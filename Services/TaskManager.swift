import Foundation
import Combine

class TaskManager: ObservableObject {
    static let shared = TaskManager()
    
    @Published var tasks: [CompressionTask] = []
    @Published var currentTask: CompressionTask?
    @Published var isProcessing: Bool = false
    
    private let compressionEngine = CompressionEngine()
    private let historyStore = HistoryStore.shared
    private let configManager = ConfigManager.shared
    private let ffmpegWrapper = FFmpegWrapper.shared
    
    private let processingQueue = DispatchQueue(label: "com.xmvideo.processing", qos: .userInitiated)
    
    // MARK: - Supported Video Formats
    // FFmpeg supports virtually all video formats
    private let supportedFormats = [
        // Common containers
        "mp4", "mov", "avi", "mkv", "flv", "wmv", "m4v", "webm",
        // Other video formats
        "mpg", "mpeg", "3gp", "rmvb", "ogv", "vob", "mts", "m2ts",
        "ts", "m2t", "dv", "dif", "gif", "mov", "qt", "rv", "rm",
        "asf", "amv", "m4p", "m4b", "m4r", "f4v", "f4p", "f4a", "f4b"
    ]
    
    private init() {}
    
    // MARK: - Task Management
    
    func addTask(fileURL: URL, profile: CompressionProfile, options: CompressionOptions) {
        // Check if file already exists in queue
        if tasks.contains(where: { $0.sourceURL == fileURL }) {
            print("File already in queue: \(fileURL.lastPathComponent)")
            return
        }
        
        // Validate file format
        let fileExtension = fileURL.pathExtension.lowercased()
        guard supportedFormats.contains(fileExtension) else {
            print("Unsupported file format: \(fileExtension)")
            return
        }
        
        // Check if file exists and is readable
        guard FileManager.default.fileExists(atPath: fileURL.path),
              FileManager.default.isReadableFile(atPath: fileURL.path) else {
            print("File not found or not readable: \(fileURL.path)")
            return
        }
        
        // Get original file size
        var originalSize: Int64? = nil
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            originalSize = attributes[.size] as? Int64
        } catch {
            print("Error getting file size: \(error)")
        }
        
        // Extract metadata
        let metadata = ffmpegWrapper.getVideoMetadata(fileURL: fileURL)
        
        // Generate output URL
        let outputURL = generateOutputURL(for: fileURL, options: options)
        
        // Create task
        let task = CompressionTask(
            sourceURL: fileURL,
            outputURL: outputURL,
            profile: profile,
            options: options,
            metadata: metadata,
            originalSize: originalSize
        )
        
        DispatchQueue.main.async {
            self.tasks.append(task)
        }
    }
    
    func addTasksFromFolder(folderURL: URL, recursive: Bool, profile: CompressionProfile, options: CompressionOptions) {
        let fileManager = FileManager.default
        
        var urls: [URL] = []
        
        if recursive {
            // Recursive scan
            if let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: [.isRegularFileKey]) {
                for case let fileURL as URL in enumerator {
                    if isVideoFile(fileURL) {
                        urls.append(fileURL)
                    }
                }
            }
        } else {
            // Non-recursive scan
            do {
                let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.isRegularFileKey])
                urls = contents.filter { isVideoFile($0) }
            } catch {
                print("Error scanning folder: \(error)")
            }
        }
        
        // Add all found videos
        for url in urls {
            addTask(fileURL: url, profile: profile, options: options)
        }
    }
    
    func removeTask(id: UUID) {
        DispatchQueue.main.async {
            self.tasks.removeAll { $0.id == id }
        }
    }
    
    func removeAllTasks() {
        DispatchQueue.main.async {
            self.tasks.removeAll()
        }
    }
    
    // MARK: - Processing
    
    func startProcessing() {
        guard !isProcessing else { return }
        guard !tasks.isEmpty else { return }
        
        isProcessing = true
        processNextTask()
    }
    
    private func processNextTask() {
        // Find next pending task
        guard let taskIndex = tasks.firstIndex(where: { $0.status == .pending }) else {
            // No more pending tasks
            isProcessing = false
            currentTask = nil
            
            // Show completion notification
            if tasks.contains(where: { $0.status == .completed }) {
                showCompletionNotification()
            }
            return
        }
        
        var task = tasks[taskIndex]
        
        // Check disk space
        guard hasSufficientDiskSpace(for: task) else {
            task.status = .failed
            task.error = "磁盘空间不足"
            updateTask(task)
            processNextTask()
            return
        }
        
        // Update task status
        task.status = .processing
        task.startedAt = Date()
        updateTask(task)
        currentTask = task
        
        // Start compression
        compressionEngine.compress(
            inputURL: task.sourceURL,
            outputURL: task.outputURL,
            profile: task.profile,
            options: task.options,
            progressHandler: { [weak self] progress in
                self?.updateTaskProgress(taskId: task.id, progress: progress)
            },
            completionHandler: { [weak self] result in
                self?.handleCompressionCompletion(taskId: task.id, result: result)
            }
        )
    }
    
    private func updateTaskProgress(taskId: UUID, progress: CompressionProgress) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        DispatchQueue.main.async {
            self.tasks[index].progress = progress
        }
    }
    
    private func handleCompressionCompletion(taskId: UUID, result: Result<URL, Error>) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        
        var task = tasks[index]
        task.completedAt = Date()
        
        switch result {
        case .success(let outputURL):
            task.status = .completed
            
            // Get compressed file size
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
                task.compressedSize = attributes[.size] as? Int64
            } catch {
                print("Error getting compressed file size: \(error)")
            }
            
            // Create history record
            createHistoryRecord(for: task)
            
            // Delete source file if option is enabled
            if task.options.deleteSourceFile {
                try? FileManager.default.removeItem(at: task.sourceURL)
            }
            
        case .failure(let error):
            task.status = .failed
            task.error = error.localizedDescription
        }
        
        updateTask(task)
        
        // Process next task
        processNextTask()
    }
    
    func cancelCurrentTask() {
        compressionEngine.cancel()
        
        if let task = currentTask {
            var updatedTask = task
            updatedTask.status = .cancelled
            updateTask(updatedTask)
        }
        
        currentTask = nil
        isProcessing = false
    }
    
    func cancelAllTasks() {
        cancelCurrentTask()
        
        for i in 0..<tasks.count {
            if tasks[i].status == .pending {
                tasks[i].status = .cancelled
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateTask(_ task: CompressionTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        DispatchQueue.main.async {
            self.tasks[index] = task
        }
    }
    
    private func isVideoFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedFormats.contains(ext)
    }
    
    private func generateOutputURL(for inputURL: URL, options: CompressionOptions) -> URL {
        let directory: URL
        if let customDir = options.customOutputDirectory {
            directory = customDir
        } else {
            directory = inputURL.deletingLastPathComponent()
        }
        
        let filename = inputURL.deletingPathExtension().lastPathComponent
        let outputExtension = inputURL.pathExtension
        let outputFilename = "\(filename)\(options.outputSuffix).\(outputExtension)"
        
        return directory.appendingPathComponent(outputFilename)
    }
    
    private func hasSufficientDiskSpace(for task: CompressionTask) -> Bool {
        guard let metadata = task.metadata else { return true }
        
        let outputDirectory = task.outputURL.deletingLastPathComponent()
        
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: outputDirectory.path)
            if let freeSpace = attributes[.systemFreeSize] as? Int64 {
                // Estimate output size (assume 50% of original for safety)
                let estimatedSize = Int64(Double(metadata.bitrate) * metadata.duration / 8.0 * 0.5)
                return freeSpace > estimatedSize * 2 // 2x safety margin
            }
        } catch {
            print("Error checking disk space: \(error)")
        }
        
        return true
    }
    
    private func createHistoryRecord(for task: CompressionTask) {
        let fileManager = FileManager.default
        
        guard let originalSize = try? fileManager.attributesOfItem(atPath: task.sourceURL.path)[.size] as? Int64,
              let compressedSize = try? fileManager.attributesOfItem(atPath: task.outputURL.path)[.size] as? Int64 else {
            return
        }
        
        let record = HistoryRecord(
            sourceFilePath: task.sourceURL.path,
            outputFilePath: task.outputURL.path,
            originalSize: originalSize,
            compressedSize: compressedSize,
            profile: task.profile.rawValue
        )
        
        historyStore.addRecord(record)
    }
    
    private func showCompletionNotification() {
        let completedCount = tasks.filter { $0.status == .completed }.count
        print("✅ 压缩完成！共处理 \(completedCount) 个文件")
        
        // TODO: Show macOS notification
    }
}

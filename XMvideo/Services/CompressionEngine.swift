import Foundation

class CompressionEngine {
    private var currentProcess: Process?
    private var progressMonitor: ProgressMonitor?
    private let ffmpegWrapper = FFmpegWrapper.shared
    
    func compress(
        inputURL: URL,
        outputURL: URL,
        profile: CompressionProfile,
        options: CompressionOptions,
        progressHandler: @escaping (CompressionProgress) -> Void,
        completionHandler: @escaping (Result<URL, Error>) -> Void
    ) {
        // Get video metadata for progress calculation
        guard let metadata = ffmpegWrapper.getVideoMetadata(fileURL: inputURL) else {
            completionHandler(.failure(CompressionError.metadataExtractionFailed))
            return
        }
        
        // Initialize progress monitor
        progressMonitor = ProgressMonitor(totalDuration: metadata.duration)
        
        // Build FFmpeg command
        let arguments = ffmpegWrapper.buildCompressionCommand(
            inputURL: inputURL,
            outputURL: outputURL,
            profile: profile,
            options: options,
            metadata: metadata
        )
        
        // Create process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegWrapper.getFFmpegPath())
        process.arguments = arguments
        
        // Setup pipes for output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Store current process
        currentProcess = process
        
        // Handle progress updates
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8),
               let progress = self?.progressMonitor?.parseProgress(output: output) {
                DispatchQueue.main.async {
                    progressHandler(progress)
                }
            }
        }
        
        // Handle process termination
        process.terminationHandler = { [weak self] process in
            // Clean up
            outputPipe.fileHandleForReading.readabilityHandler = nil
            self?.currentProcess = nil
            
            DispatchQueue.main.async {
                if process.terminationStatus == 0 {
                    completionHandler(.success(outputURL))
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    completionHandler(.failure(CompressionError.ffmpegFailed(message: errorMessage)))
                }
            }
        }
        
        // Start process
        do {
            try process.run()
        } catch {
            currentProcess = nil
            completionHandler(.failure(CompressionError.processStartFailed(error: error)))
        }
    }
    
    func cancel() {
        guard let process = currentProcess, process.isRunning else {
            return
        }
        
        process.terminate()
        
        // Force kill if still running after 2 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak process] in
            if let process = process, process.isRunning {
                process.interrupt()
            }
        }
        
        currentProcess = nil
    }
    
    func getVideoMetadata(fileURL: URL) -> VideoMetadata? {
        return ffmpegWrapper.getVideoMetadata(fileURL: fileURL)
    }
}

enum CompressionError: LocalizedError {
    case metadataExtractionFailed
    case ffmpegFailed(message: String)
    case processStartFailed(error: Error)
    case fileNotFound
    case insufficientDiskSpace
    
    var errorDescription: String? {
        switch self {
        case .metadataExtractionFailed:
            return "无法读取视频信息"
        case .ffmpegFailed(let message):
            return "视频压缩失败: \(message)"
        case .processStartFailed(let error):
            return "无法启动压缩进程: \(error.localizedDescription)"
        case .fileNotFound:
            return "文件不存在或无法访问"
        case .insufficientDiskSpace:
            return "磁盘空间不足"
        }
    }
}

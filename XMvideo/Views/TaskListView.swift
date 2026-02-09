import SwiftUI
import UniformTypeIdentifiers

struct TaskListView: View {
    @ObservedObject var taskManager = TaskManager.shared
    @ObservedObject var configManager = ConfigManager.shared
    @State private var isDragging = false
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            topToolbar
            
            Divider()
            
            // Main content area
            if taskManager.tasks.isEmpty {
                emptyDropZone
            } else {
                taskListWithDrop
                
                Divider()
                
                // Bottom control bar (only show when there are tasks)
                bottomControlBar
            }
        }
    }
    
    // MARK: - Top Toolbar
    
    private var topToolbar: some View {
        HStack {
            // Profile selector
            Picker("配置", selection: $configManager.selectedProfile) {
                ForEach(CompressionProfile.allCases) { profile in
                    Text(profile.rawValue).tag(profile)
                }
            }
            .frame(width: 120)
            
            Spacer()
            
            // Settings button
            Button(action: {
                selectedTab = 2
            }) {
                Image(systemName: "gearshape")
            }
            .help("设置")
            
            // History button
            Button(action: {
                selectedTab = 1
            }) {
                Image(systemName: "clock.arrow.circlepath")
            }
            .help("历史记录")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Empty State (Large Drop Zone)
    
    private var emptyDropZone: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: isDragging ? "video.badge.plus" : "video.fill")
                .font(.system(size: 64))
                .foregroundColor(isDragging ? .accentColor : .secondary)
            
            VStack(spacing: 8) {
                Text(isDragging ? "松开以添加" : "拖拽视频文件或文件夹")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(isDragging ? .accentColor : .primary)
                
                Text("支持 MP4, MOV, AVI, MKV 等格式")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDragging ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .padding(20)
        )
        .background(isDragging ? Color.accentColor.opacity(0.05) : Color.clear)
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    // MARK: - Task List with Drop Support
    
    private var taskListWithDrop: some View {
        ZStack {
            // Task list
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("📋 任务列表")
                            .font(.headline)
                        
                        Text("(\(taskManager.tasks.count)个文件)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Task items
                    LazyVStack(spacing: 1) {
                        ForEach(taskManager.tasks) { task in
                            TaskItemView(task: task)
                            
                            if task.id != taskManager.tasks.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            // Drop overlay (only when not processing)
            if !taskManager.isProcessing {
                Color.clear
                    .contentShape(Rectangle())
                    .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                        handleDrop(providers: providers)
                        return true
                    }
                
                if isDragging {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.accentColor, lineWidth: 3)
                        .background(Color.accentColor.opacity(0.1))
                        .padding(8)
                        .allowsHitTesting(false)
                }
            } else if isDragging {
                // Processing state - show disabled overlay
                ZStack {
                    Color.black.opacity(0.3)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("处理中无法添加新任务")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .cornerRadius(8)
                .padding(8)
                .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Bottom Control Bar
    
    private var bottomControlBar: some View {
        HStack {
            // Clear button
            Button("清空") {
                taskManager.removeAllTasks()
            }
            .disabled(taskManager.tasks.isEmpty || taskManager.isProcessing)
            
            Spacer()
            
            // Start/Stop button
            Button(action: {
                if taskManager.isProcessing {
                    taskManager.cancelAllTasks()
                } else {
                    taskManager.startProcessing()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: taskManager.isProcessing ? "stop.fill" : "play.fill")
                    Text(taskManager.isProcessing ? "停止处理" : "开始压缩")
                }
                .frame(minWidth: 100)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .disabled(taskManager.tasks.isEmpty || (!taskManager.isProcessing && taskManager.tasks.allSatisfy { $0.status != .pending }))
            .keyboardShortcut(.return, modifiers: [.command])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Drop Handler
    
    private func handleDrop(providers: [NSItemProvider]) {
        // Don't allow drop while processing
        guard !taskManager.isProcessing else { return }
        
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url = url else { return }
                
                DispatchQueue.main.async {
                    if url.hasDirectoryPath {
                        // It's a folder
                        taskManager.addTasksFromFolder(
                            folderURL: url,
                            recursive: configManager.recursiveScan,
                            profile: configManager.selectedProfile,
                            options: configManager.compressionOptions
                        )
                    } else {
                        // It's a file
                        taskManager.addTask(
                            fileURL: url,
                            profile: configManager.selectedProfile,
                            options: configManager.compressionOptions
                        )
                    }
                }
            }
        }
    }
}

struct TaskItemView: View {
    let task: CompressionTask
    @ObservedObject var taskManager = TaskManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status icon
            statusIcon
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // File name
                Text(task.sourceURL.lastPathComponent)
                    .font(.system(.body, design: .default))
                    .lineLimit(1)
                
                // Status info
                statusInfo
            }
            
            Spacer()
            
            // Remove button (only for pending tasks)
            if task.status == .pending {
                Button(action: {
                    taskManager.removeTask(id: task.id)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 18))
                }
                .help("移除")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var statusIcon: some View {
        Group {
            switch task.status {
            case .pending:
                Image(systemName: "clock.fill")
                    .foregroundColor(.secondary)
            case .processing:
                ProgressView()
                    .scaleEffect(0.8)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .cancelled:
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var statusInfo: some View {
        Group {
            switch task.status {
            case .pending:
                pendingInfo
            case .processing:
                processingInfo
            case .completed:
                completedInfo
            case .failed:
                failedInfo
            case .cancelled:
                cancelledInfo
            }
        }
    }
    
    private var pendingInfo: some View {
        HStack(spacing: 8) {
            if let size = task.originalSize {
                Text(formatFileSize(size))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("等待中")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var processingInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let size = task.originalSize {
                Text(formatFileSize(size))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let progress = task.progress {
                // Progress bar
                ProgressView(value: progress.percentage)
                    .progressViewStyle(.linear)
                
                // Progress details
                HStack(spacing: 12) {
                    Text(progress.percentageString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if progress.fps > 0 {
                        Text("\(Int(progress.fps)) fps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if progress.estimatedTimeRemaining > 0 {
                        Text("剩余 \(formatDuration(progress.estimatedTimeRemaining))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var completedInfo: some View {
        HStack(spacing: 8) {
            if let originalSize = task.originalSize,
               let compressedSize = task.compressedSize {
                
                let ratio = Double(compressedSize) / Double(originalSize)
                let savedPercent = Int((1.0 - ratio) * 100)
                
                HStack(spacing: 4) {
                    Text(formatFileSize(originalSize))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatFileSize(compressedSize))
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    if savedPercent > 0 {
                        Text("(节省 \(savedPercent)%)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            } else if let originalSize = task.originalSize {
                // Fallback: show original size only
                HStack(spacing: 4) {
                    Text(formatFileSize(originalSize))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("→ 已完成")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else {
                Text("已完成")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
    }
    
    private var failedInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let size = task.originalSize {
                Text(formatFileSize(size))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let error = task.error {
                Text("失败: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(2)
            }
        }
    }
    
    private var cancelledInfo: some View {
        HStack(spacing: 8) {
            if let size = task.originalSize {
                Text(formatFileSize(size))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("已取消")
                .font(.subheadline)
                .foregroundColor(.orange)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes)分\(secs)秒"
        } else {
            return "\(secs)秒"
        }
    }
}

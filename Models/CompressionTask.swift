import Foundation

struct CompressionTask: Identifiable, Codable {
    var id: UUID
    var sourceURL: URL
    var outputURL: URL
    var profile: CompressionProfile
    var options: CompressionOptions
    var status: TaskStatus
    var progress: CompressionProgress?
    var metadata: VideoMetadata?
    var error: String?
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var originalSize: Int64?
    var compressedSize: Int64?
    
    init(
        id: UUID = UUID(),
        sourceURL: URL,
        outputURL: URL,
        profile: CompressionProfile,
        options: CompressionOptions,
        status: TaskStatus = .pending,
        progress: CompressionProgress? = nil,
        metadata: VideoMetadata? = nil,
        error: String? = nil,
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        originalSize: Int64? = nil,
        compressedSize: Int64? = nil
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.outputURL = outputURL
        self.profile = profile
        self.options = options
        self.status = status
        self.progress = progress
        self.metadata = metadata
        self.error = error
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.originalSize = originalSize
        self.compressedSize = compressedSize
    }
}

enum TaskStatus: String, Codable {
    case pending = "等待中"
    case processing = "处理中"
    case completed = "已完成"
    case failed = "失败"
    case cancelled = "已取消"
}

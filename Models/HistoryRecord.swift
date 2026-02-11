import Foundation

struct HistoryRecord: Codable, Identifiable {
    var id: UUID
    var sourceFilePath: String
    var outputFilePath: String
    var originalSize: Int64
    var compressedSize: Int64
    var compressionRatio: Double
    var timestamp: Date
    var profile: String
    
    init(
        id: UUID = UUID(),
        sourceFilePath: String,
        outputFilePath: String,
        originalSize: Int64,
        compressedSize: Int64,
        timestamp: Date = Date(),
        profile: String
    ) {
        self.id = id
        self.sourceFilePath = sourceFilePath
        self.outputFilePath = outputFilePath
        self.originalSize = originalSize
        self.compressedSize = compressedSize
        self.compressionRatio = compressedSize > 0 ? Double(compressedSize) / Double(originalSize) : 0.0
        self.timestamp = timestamp
        self.profile = profile
    }
    
    var originalSizeString: String {
        return ByteCountFormatter.string(fromByteCount: originalSize, countStyle: .file)
    }
    
    var compressedSizeString: String {
        return ByteCountFormatter.string(fromByteCount: compressedSize, countStyle: .file)
    }
    
    var compressionRatioString: String {
        return String(format: "%.1f%%", compressionRatio * 100)
    }
    
    var savedSizeString: String {
        let saved = originalSize - compressedSize
        return ByteCountFormatter.string(fromByteCount: saved, countStyle: .file)
    }
    
    var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

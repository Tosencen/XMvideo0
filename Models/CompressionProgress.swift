import Foundation

struct CompressionProgress: Codable {
    var percentage: Double      // 0.0 - 1.0
    var currentFrame: Int
    var fps: Double
    var processedDuration: Double  // in seconds
    var estimatedTimeRemaining: TimeInterval
    var currentFileSize: Int64
    
    init(
        percentage: Double = 0.0,
        currentFrame: Int = 0,
        fps: Double = 0.0,
        processedDuration: Double = 0.0,
        estimatedTimeRemaining: TimeInterval = 0.0,
        currentFileSize: Int64 = 0
    ) {
        self.percentage = percentage
        self.currentFrame = currentFrame
        self.fps = fps
        self.processedDuration = processedDuration
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.currentFileSize = currentFileSize
    }
    
    var percentageString: String {
        return String(format: "%.1f%%", percentage * 100)
    }
    
    var fpsString: String {
        return String(format: "%.1f fps", fps)
    }
    
    var timeRemainingString: String {
        let minutes = Int(estimatedTimeRemaining) / 60
        let seconds = Int(estimatedTimeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: currentFileSize, countStyle: .file)
    }
}

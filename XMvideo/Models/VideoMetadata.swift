import Foundation

struct VideoMetadata: Codable {
    var duration: Double        // in seconds
    var width: Int
    var height: Int
    var codec: String
    var bitrate: Int64          // bps
    var fps: Double
    var rotation: Int           // 0, 90, 180, 270
    var hasAudio: Bool
    
    init(
        duration: Double = 0.0,
        width: Int = 0,
        height: Int = 0,
        codec: String = "unknown",
        bitrate: Int64 = 0,
        fps: Double = 0.0,
        rotation: Int = 0,
        hasAudio: Bool = false
    ) {
        self.duration = duration
        self.width = width
        self.height = height
        self.codec = codec
        self.bitrate = bitrate
        self.fps = fps
        self.rotation = rotation
        self.hasAudio = hasAudio
    }
    
    var resolutionString: String {
        return "\(width)x\(height)"
    }
    
    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var bitrateString: String {
        let kbps = Double(bitrate) / 1000.0
        return String(format: "%.0f kbps", kbps)
    }
    
    var fpsString: String {
        return String(format: "%.0f fps", fps)
    }
}

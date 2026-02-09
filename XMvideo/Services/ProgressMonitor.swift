import Foundation

class ProgressMonitor {
    private var startTime: Date?
    private var totalDuration: Double
    
    init(totalDuration: Double) {
        self.totalDuration = totalDuration
        self.startTime = Date()
    }
    
    func parseProgress(output: String) -> CompressionProgress? {
        // FFmpeg progress output format:
        // frame=123
        // fps=45.67
        // total_size=1234567
        // out_time_ms=5000000
        // progress=continue
        
        var frame: Int = 0
        var fps: Double = 0.0
        var totalSize: Int64 = 0
        var outTimeMs: Int64 = 0
        
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let components = line.components(separatedBy: "=")
            guard components.count == 2 else { continue }
            
            let key = components[0].trimmingCharacters(in: .whitespaces)
            let value = components[1].trimmingCharacters(in: .whitespaces)
            
            switch key {
            case "frame":
                frame = Int(value) ?? 0
            case "fps":
                fps = Double(value) ?? 0.0
            case "total_size":
                totalSize = Int64(value) ?? 0
            case "out_time_ms":
                outTimeMs = Int64(value) ?? 0
            default:
                break
            }
        }
        
        // Convert microseconds to seconds
        let processedDuration = Double(outTimeMs) / 1_000_000.0
        
        // Calculate percentage
        let percentage = totalDuration > 0 ? min(processedDuration / totalDuration, 1.0) : 0.0
        
        // Calculate estimated time remaining
        let elapsedTime = startTime?.timeIntervalSinceNow ?? 0
        let estimatedTimeRemaining: TimeInterval
        
        if processedDuration > 0 && elapsedTime < 0 {
            let totalEstimatedTime = (totalDuration / processedDuration) * abs(elapsedTime)
            estimatedTimeRemaining = max(totalEstimatedTime - abs(elapsedTime), 0)
        } else {
            estimatedTimeRemaining = 0
        }
        
        return CompressionProgress(
            percentage: percentage,
            currentFrame: frame,
            fps: fps,
            processedDuration: processedDuration,
            estimatedTimeRemaining: estimatedTimeRemaining,
            currentFileSize: totalSize
        )
    }
    
    func reset() {
        startTime = Date()
    }
}

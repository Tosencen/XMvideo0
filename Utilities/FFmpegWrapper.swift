import Foundation

class FFmpegWrapper {
    static let shared = FFmpegWrapper()
    
    private let ffmpegPath: String
    private let ffprobePath: String
    
    private init() {
        // Try to find ffmpeg in common locations
        let possiblePaths = [
            "/usr/local/bin/ffmpeg",
            "/opt/homebrew/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        
        self.ffmpegPath = possiblePaths.first { FileManager.default.fileExists(atPath: $0) } ?? "ffmpeg"
        
        let possibleProbePaths = [
            "/usr/local/bin/ffprobe",
            "/opt/homebrew/bin/ffprobe",
            "/usr/bin/ffprobe"
        ]
        
        self.ffprobePath = possibleProbePaths.first { FileManager.default.fileExists(atPath: $0) } ?? "ffprobe"
    }
    
    // MARK: - FFmpeg Availability
    
    func isFFmpegAvailable() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = ["-version"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func getFFmpegVersion() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = ["-version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                return lines.first
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    // MARK: - Video Metadata Extraction
    
    func getVideoMetadata(fileURL: URL) -> VideoMetadata? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffprobePath)
        process.arguments = [
            "-v", "quiet",
            "-print_format", "json",
            "-show_format",
            "-show_streams",
            fileURL.path
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            
            return parseMetadata(from: json)
        } catch {
            print("Error extracting metadata: \(error)")
            return nil
        }
    }
    
    private func parseMetadata(from json: [String: Any]) -> VideoMetadata? {
        guard let streams = json["streams"] as? [[String: Any]] else {
            return nil
        }
        
        // Find video stream
        guard let videoStream = streams.first(where: { ($0["codec_type"] as? String) == "video" }) else {
            return nil
        }
        
        // Find audio stream
        let hasAudio = streams.contains { ($0["codec_type"] as? String) == "audio" }
        
        // Extract format info
        let format = json["format"] as? [String: Any]
        
        let duration = (format?["duration"] as? String).flatMap { Double($0) } ?? 0.0
        let bitrate = (format?["bit_rate"] as? String).flatMap { Int64($0) } ?? 0
        
        let width = videoStream["width"] as? Int ?? 0
        let height = videoStream["height"] as? Int ?? 0
        let codec = videoStream["codec_name"] as? String ?? "unknown"
        
        // Parse FPS
        let fpsString = videoStream["r_frame_rate"] as? String ?? "0/1"
        let fpsComponents = fpsString.components(separatedBy: "/")
        let fps: Double
        if fpsComponents.count == 2,
           let num = Double(fpsComponents[0]),
           let den = Double(fpsComponents[1]),
           den > 0 {
            fps = num / den
        } else {
            fps = 0.0
        }
        
        // Parse rotation
        let tags = videoStream["tags"] as? [String: Any]
        let rotationString = tags?["rotate"] as? String
        let rotation = rotationString.flatMap { Int($0) } ?? 0
        
        return VideoMetadata(
            duration: duration,
            width: width,
            height: height,
            codec: codec,
            bitrate: bitrate,
            fps: fps,
            rotation: rotation,
            hasAudio: hasAudio
        )
    }
    
    // MARK: - FFmpeg Command Building
    
    func buildCompressionCommand(
        inputURL: URL,
        outputURL: URL,
        profile: CompressionProfile,
        options: CompressionOptions,
        metadata: VideoMetadata? = nil
    ) -> [String] {
        var arguments: [String] = []
        
        // Overwrite output file without asking
        arguments += ["-y"]
        
        // Hardware acceleration (must be before input)
        if options.useHardwareAcceleration {
            arguments += ["-hwaccel", "auto"]
        }
        
        // Input file
        arguments += ["-i", inputURL.path]
        
        let params = profile.parameters
        
        // Video codec - use libx264 for better compression
        arguments += ["-c:v", "libx264"]
        
        // CRF (quality) - lower is better quality
        arguments += ["-crf", "\(params.crf)"]
        
        // Preset (speed vs compression efficiency)
        arguments += ["-preset", params.preset]
        
        // GOP size (keyframe interval)
        arguments += ["-keyint_min", "\(params.gop)"]
        arguments += ["-g", "\(params.gop)"]
        
        // Reference frames
        arguments += ["-refs", "\(params.refs)"]
        
        // B-frames
        arguments += ["-bf", "\(params.bframes)"]
        
        // Motion estimation method - umh is good balance
        arguments += ["-me_method", "umh"]
        
        // Scene change threshold
        arguments += ["-sc_threshold", "60"]
        
        // B-frame strategy
        arguments += ["-b_strategy", "1"]
        
        // Quantizer curve compression
        arguments += ["-qcomp", "0.5"]
        
        // Psychovisual rate-distortion optimization
        arguments += ["-psy-rd", "0.3:0"]
        
        // Adaptive quantization mode
        arguments += ["-aq-mode", "2"]
        
        // Adaptive quantization strength
        arguments += ["-aq-strength", "0.8"]
        
        // Handle video rotation if needed
        if let metadata = metadata, metadata.rotation != 0 {
            let transpose: String
            switch metadata.rotation {
            case 90:
                transpose = "transpose=1"
            case 180:
                transpose = "transpose=1,transpose=1"
            case 270:
                transpose = "transpose=2"
            default:
                transpose = ""
            }
            
            if !transpose.isEmpty {
                arguments += ["-vf", transpose]
                // Reset rotation metadata
                arguments += ["-metadata:s:v", "rotate=0"]
            }
        }
        
        // Audio handling
        if options.removeAudio {
            arguments += ["-an"]
        } else {
            // Re-encode audio to AAC at 128k for better compatibility
            arguments += ["-c:a", "aac"]
            arguments += ["-b:a", "128k"]
        }
        
        // Optimize for streaming (move moov atom to beginning)
        arguments += ["-movflags", "faststart"]
        
        // Map all streams (must be after codec settings)
        arguments += ["-map", "0:"]
        
        // Progress output
        arguments += ["-progress", "pipe:1"]
        
        // Disable stdin interaction
        arguments += ["-nostdin"]
        
        // Output file
        arguments.append(outputURL.path)
        
        return arguments
    }
    
    func getFFmpegPath() -> String {
        return ffmpegPath
    }
}

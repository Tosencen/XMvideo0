import Foundation
import AppKit

class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    // MARK: - Error Logging
    
    func logError(_ error: Error, context: String = "") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let message = "[\(timestamp)] \(context): \(error.localizedDescription)"
        
        print("❌ \(message)")
        
        // Write to log file
        writeToLogFile(message)
    }
    
    func logWarning(_ message: String, context: String = "") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] WARNING \(context): \(message)"
        
        print("⚠️ \(logMessage)")
        
        writeToLogFile(logMessage)
    }
    
    func logInfo(_ message: String, context: String = "") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] INFO \(context): \(message)"
        
        print("ℹ️ \(logMessage)")
        
        writeToLogFile(logMessage)
    }
    
    private func writeToLogFile(_ message: String) {
        let logDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("XMvideo")
        
        guard let logDirectory = logDirectory else { return }
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        
        let logFile = logDirectory.appendingPathComponent("xmvideo.log")
        
        let logLine = message + "\n"
        
        if let data = logLine.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
    }
    
    // MARK: - User-Friendly Error Messages
    
    func getUserFriendlyMessage(for error: Error) -> String {
        if let compressionError = error as? CompressionError {
            return compressionError.errorDescription ?? "未知错误"
        }
        
        // Map common errors to user-friendly messages
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSCocoaErrorDomain:
            switch nsError.code {
            case NSFileReadNoSuchFileError:
                return "文件不存在或已被删除"
            case NSFileReadNoPermissionError:
                return "没有权限读取文件"
            case NSFileWriteNoPermissionError:
                return "没有权限写入文件"
            case NSFileWriteOutOfSpaceError:
                return "磁盘空间不足"
            default:
                return "文件操作失败"
            }
            
        case NSPOSIXErrorDomain:
            switch nsError.code {
            case Int(EACCES):
                return "权限不足"
            case Int(ENOSPC):
                return "磁盘空间不足"
            case Int(ENOENT):
                return "文件不存在"
            default:
                return "系统错误"
            }
            
        default:
            return "操作失败，请重试"
        }
    }
    
    // MARK: - Error Alerts
    
    func showErrorAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    func showErrorAlert(for error: Error, context: String = "") {
        let message = getUserFriendlyMessage(for: error)
        let title = context.isEmpty ? "错误" : context
        
        logError(error, context: context)
        showErrorAlert(title: title, message: message)
    }
    
    // MARK: - Error Recovery
    
    func canRetry(error: Error) -> Bool {
        if let compressionError = error as? CompressionError {
            switch compressionError {
            case .metadataExtractionFailed, .ffmpegFailed:
                return true
            case .fileNotFound, .insufficientDiskSpace:
                return false
            case .processStartFailed:
                return true
            }
        }
        
        let nsError = error as NSError
        
        // Temporary errors that can be retried
        let retryableCodes = [
            NSFileReadUnknownError,
            NSFileWriteUnknownError,
            Int(EAGAIN),
            Int(EINTR)
        ]
        
        return retryableCodes.contains(nsError.code)
    }
}

// MARK: - Error Types

enum AppError: LocalizedError {
    case ffmpegNotInstalled
    case invalidVideoFile
    case compressionCancelled
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .ffmpegNotInstalled:
            return "FFmpeg 未安装。请使用 Homebrew 安装：brew install ffmpeg"
        case .invalidVideoFile:
            return "不支持的视频格式"
        case .compressionCancelled:
            return "压缩已取消"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

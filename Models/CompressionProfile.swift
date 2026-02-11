import Foundation

enum CompressionProfile: String, CaseIterable, Identifiable, Codable {
    case `default` = "默认"
    case fast = "快速"
    case highQuality = "高质量"
    
    var id: String { rawValue }
    
    var parameters: CompressionParameters {
        switch self {
        case .default:
            // 类似 VideoSlim 的默认配置
            return CompressionParameters(crf: 23, preset: "veryslow", gop: 600, bframes: 3, refs: 4)
        case .fast:
            return CompressionParameters(crf: 26, preset: "medium", gop: 250, bframes: 2, refs: 3)
        case .highQuality:
            return CompressionParameters(crf: 20, preset: "veryslow", gop: 600, bframes: 4, refs: 5)
        }
    }
    
    var description: String {
        switch self {
        case .default:
            return "平衡质量和速度，适合大多数场景"
        case .fast:
            return "快速处理，适合批量压缩"
        case .highQuality:
            return "高质量输出，处理时间较长"
        }
    }
}

struct CompressionParameters: Codable {
    var crf: Int              // 18-28 推荐范围
    var preset: String        // ultrafast, fast, medium, slow, veryslow
    var gop: Int              // GOP 大小，通常为帧率的 10 倍
    var bframes: Int          // B 帧数量 (0-4)
    var refs: Int             // 参考帧数量 (1-6)
}

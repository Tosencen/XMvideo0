import Foundation

struct CompressionOptions: Codable {
    var removeAudio: Bool = false
    var deleteSourceFile: Bool = false
    var useHardwareAcceleration: Bool = true
    var customOutputDirectory: URL? = nil
    var outputSuffix: String = "_compressed"
    
    init(
        removeAudio: Bool = false,
        deleteSourceFile: Bool = false,
        useHardwareAcceleration: Bool = true,
        customOutputDirectory: URL? = nil,
        outputSuffix: String = "_compressed"
    ) {
        self.removeAudio = removeAudio
        self.deleteSourceFile = deleteSourceFile
        self.useHardwareAcceleration = useHardwareAcceleration
        self.customOutputDirectory = customOutputDirectory
        self.outputSuffix = outputSuffix
    }
}

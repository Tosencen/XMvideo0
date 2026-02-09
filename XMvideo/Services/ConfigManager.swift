import Foundation
import Combine

class ConfigManager: ObservableObject {
    static let shared = ConfigManager()
    
    @Published var selectedProfile: CompressionProfile
    @Published var compressionOptions: CompressionOptions
    @Published var recursiveScan: Bool
    
    private let selectedProfileKey = "selectedProfile"
    private let compressionOptionsKey = "compressionOptions"
    private let recursiveScanKey = "recursiveScan"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load saved preferences or use defaults
        if let profileRawValue = UserDefaults.standard.string(forKey: selectedProfileKey),
           let profile = CompressionProfile(rawValue: profileRawValue) {
            self.selectedProfile = profile
        } else {
            self.selectedProfile = .default
        }
        
        if let optionsData = UserDefaults.standard.data(forKey: compressionOptionsKey),
           let options = try? JSONDecoder().decode(CompressionOptions.self, from: optionsData) {
            self.compressionOptions = options
        } else {
            self.compressionOptions = CompressionOptions()
        }
        
        self.recursiveScan = UserDefaults.standard.bool(forKey: recursiveScanKey)
        
        // Auto-save when properties change
        setupAutoSave()
    }
    
    private func setupAutoSave() {
        $selectedProfile
            .dropFirst() // Skip initial value
            .sink { [weak self] profile in
                self?.saveSelectedProfile(profile)
            }
            .store(in: &cancellables)
        
        $compressionOptions
            .dropFirst()
            .sink { [weak self] options in
                self?.saveCompressionOptions(options)
            }
            .store(in: &cancellables)
        
        $recursiveScan
            .dropFirst()
            .sink { [weak self] recursive in
                self?.saveRecursiveScan(recursive)
            }
            .store(in: &cancellables)
    }
    
    func loadPreferences() {
        // Reload from UserDefaults
        if let profileRawValue = UserDefaults.standard.string(forKey: selectedProfileKey),
           let profile = CompressionProfile(rawValue: profileRawValue) {
            self.selectedProfile = profile
        }
        
        if let optionsData = UserDefaults.standard.data(forKey: compressionOptionsKey),
           let options = try? JSONDecoder().decode(CompressionOptions.self, from: optionsData) {
            self.compressionOptions = options
        }
        
        self.recursiveScan = UserDefaults.standard.bool(forKey: recursiveScanKey)
    }
    
    func savePreferences() {
        saveSelectedProfile(selectedProfile)
        saveCompressionOptions(compressionOptions)
        saveRecursiveScan(recursiveScan)
    }
    
    private func saveSelectedProfile(_ profile: CompressionProfile) {
        UserDefaults.standard.set(profile.rawValue, forKey: selectedProfileKey)
    }
    
    private func saveCompressionOptions(_ options: CompressionOptions) {
        if let data = try? JSONEncoder().encode(options) {
            UserDefaults.standard.set(data, forKey: compressionOptionsKey)
        }
    }
    
    private func saveRecursiveScan(_ recursive: Bool) {
        UserDefaults.standard.set(recursive, forKey: recursiveScanKey)
    }
    
    func resetToDefaults() {
        selectedProfile = .default
        compressionOptions = CompressionOptions()
        recursiveScan = false
    }
}

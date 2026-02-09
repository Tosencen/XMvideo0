import SwiftUI

struct SettingsView: View {
    @ObservedObject var configManager = ConfigManager.shared
    @State private var showingFolderPicker = false
    @Binding var selectedTab: Int
    
    // Local state for compression options
    @State private var removeAudio = false
    @State private var deleteSourceFile = false
    @State private var useHardwareAcceleration = true
    @State private var recursiveScan = false
    @State private var outputSuffix = "_compressed"
    @State private var customOutputDirectory: URL? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            topToolbar
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile section
                    profileSection
                    
                    // Advanced options
                    advancedOptionsSection
                    
                    // Output settings
                    outputSettingsSection
                    
                    // About section
                    aboutSection
                }
                .padding(20)
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        removeAudio = configManager.compressionOptions.removeAudio
        deleteSourceFile = configManager.compressionOptions.deleteSourceFile
        useHardwareAcceleration = configManager.compressionOptions.useHardwareAcceleration
        recursiveScan = configManager.recursiveScan
        outputSuffix = configManager.compressionOptions.outputSuffix
        customOutputDirectory = configManager.compressionOptions.customOutputDirectory
    }
    
    private func updateRemoveAudio(_ value: Bool) {
        removeAudio = value
        configManager.compressionOptions.removeAudio = value
    }
    
    private func updateDeleteSourceFile(_ value: Bool) {
        deleteSourceFile = value
        configManager.compressionOptions.deleteSourceFile = value
    }
    
    private func updateUseHardwareAcceleration(_ value: Bool) {
        useHardwareAcceleration = value
        configManager.compressionOptions.useHardwareAcceleration = value
    }
    
    private func updateRecursiveScan(_ value: Bool) {
        recursiveScan = value
        configManager.recursiveScan = value
    }
    
    private func updateOutputSuffix(_ value: String) {
        outputSuffix = value
        configManager.compressionOptions.outputSuffix = value
    }
    
    private func updateCustomOutputDirectory(_ value: URL?) {
        customOutputDirectory = value
        configManager.compressionOptions.customOutputDirectory = value
    }
    
    private var topToolbar: some View {
        HStack {
            Button(action: {
                selectedTab = 0
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 13))
                }
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("设置")
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
            
            // Placeholder for symmetry
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text("返回")
                    .font(.system(size: 13))
            }
            .opacity(0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("压缩配置")
                .font(.system(size: 15, weight: .semibold))
            
            VStack(spacing: 12) {
                ForEach(CompressionProfile.allCases) { profile in
                    ProfileOptionView(
                        profile: profile,
                        isSelected: configManager.selectedProfile == profile,
                        action: {
                            configManager.selectedProfile = profile
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("高级选项")
                .font(.system(size: 15, weight: .semibold))
            
            VStack(spacing: 12) {
                DirectToggleOptionView(
                    title: "删除音频轨道",
                    description: "移除视频中的所有音频",
                    isOn: removeAudio,
                    onChange: updateRemoveAudio
                )
                
                DirectToggleOptionView(
                    title: "删除源文件",
                    description: "压缩成功后自动删除原始文件",
                    isOn: deleteSourceFile,
                    onChange: updateDeleteSourceFile
                )
                
                DirectToggleOptionView(
                    title: "使用硬件加速",
                    description: "使用 VideoToolbox 提升编码速度",
                    isOn: useHardwareAcceleration,
                    onChange: updateUseHardwareAcceleration
                )
                
                DirectToggleOptionView(
                    title: "递归扫描文件夹",
                    description: "处理所有子文件夹中的视频",
                    isOn: recursiveScan,
                    onChange: updateRecursiveScan
                )
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var outputSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("输出设置")
                .font(.system(size: 15, weight: .semibold))
            
            VStack(spacing: 20) {
                // Output directory
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("输出目录")
                                .font(.system(size: 13, weight: .semibold))
                            
                            Text("选择视频压缩后的保存位置")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    if let customDir = customOutputDirectory {
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(customDir.lastPathComponent)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                    
                                    Text(customDir.path)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    updateCustomOutputDirectory(nil)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                            )
                            
                            Button(action: {
                                selectOutputDirectory()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 12))
                                    Text("更改目录")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("与源文件相同位置")
                                        .font(.system(size: 13, weight: .medium))
                                    
                                    Text("压缩后的视频将保存在原文件旁边")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(14)
                            .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                            .cornerRadius(8)
                            
                            Button(action: {
                                selectOutputDirectory()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 13))
                                    Text("选择自定义目录")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(7)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // Output suffix
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("文件名后缀")
                            .font(.system(size: 13, weight: .semibold))
                        
                        Text("为压缩后的文件添加标识后缀")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Text("原文件名")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 70, alignment: .trailing)
                            
                            TextField("", text: Binding(
                                get: { outputSuffix },
                                set: { newValue in
                                    outputSuffix = newValue
                                    updateOutputSuffix(newValue)
                                }
                            ))
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(7)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1.5)
                                )
                            
                            Text(".mp4")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)
                        }
                        
                        // Example preview
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            
                            Text("示例：")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("video\(outputSuffix).mp4")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.08))
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("关于")
                .font(.system(size: 15, weight: .semibold))
            
            VStack(spacing: 12) {
                HStack {
                    Text("版本")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1.0.0")
                        .font(.system(size: 13))
                }
                
                Divider()
                
                HStack {
                    Text("FFmpeg")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                    if FFmpegWrapper.shared.isFFmpegAvailable() {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                            Text("已安装")
                                .font(.system(size: 13))
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                            Text("未安装")
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if !FFmpegWrapper.shared.isFFmpegAvailable() {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("安装 FFmpeg")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Text("brew install ffmpeg")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "选择输出目录"
        
        if panel.runModal() == .OK, let url = panel.url {
            updateCustomOutputDirectory(url)
        }
    }
}

// MARK: - Profile Option View

struct ProfileOptionView: View {
    let profile: CompressionProfile
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(profile.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                // Parameters
                let params = profile.parameters
                Text("CRF: \(params.crf) • Preset: \(params.preset) • GOP: \(params.gop)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.textBackgroundColor).opacity(0.3))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Direct Toggle Option View (without Binding)

struct DirectToggleOptionView: View {
    let title: String
    let description: String
    let isOn: Bool
    let onChange: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onChange(!isOn)
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isOn ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 40, height: 24)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .offset(x: isOn ? 8 : -8)
                }
            }
            .padding(12)
            .background(Color(NSColor.textBackgroundColor).opacity(0.5))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toggle Option View (with Binding)

struct ToggleOptionView: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(12)
        .background(Color(NSColor.textBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(selectedTab: .constant(2))
            .frame(width: 400, height: 500)
    }
}

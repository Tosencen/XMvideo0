# XMvideo - macOS 菜单栏视频压缩工具

XMvideo 是一个原生 macOS 菜单栏应用，提供便捷的视频压缩功能。

## 功能特性

- ✅ **菜单栏集成**：常驻菜单栏，不占用 Dock 空间
- ✅ **拖拽操作**：支持拖拽视频文件或文件夹
- ✅ **多种配置**：默认、快速、高质量、极致压缩四种预设方案
- ✅ **批量处理**：支持递归扫描文件夹，批量压缩
- ✅ **实时进度**：显示压缩进度、速度和预估时间
- ✅ **文件大小显示**：显示原始大小、压缩后大小和节省百分比
- ✅ **高级选项**：
  - 删除音频轨道
  - 删除源文件
  - 硬件加速（VideoToolbox）
  - 自定义输出目录
  - 自定义文件名后缀
- ✅ **历史记录**：查看压缩历史和统计信息
- ✅ **视频旋转修正**：自动处理旋转元数据
- ✅ **元数据保留**：保留视频创建日期

## 系统要求

- macOS 11.0 (Big Sur) 或更高版本
- FFmpeg（需要单独安装）

## 安装 FFmpeg

使用 Homebrew 安装 FFmpeg：

```bash
brew install ffmpeg
```

## 构建项目

### 前置要求

- Xcode 13 或更高版本
- Swift 5.0+
- xcodegen（用于生成项目文件）

### 安装 xcodegen

```bash
brew install xcodegen
```

### 构建步骤

1. 克隆项目：
```bash
git clone https://github.com/Tosencen/XMvideo.git
cd XMvideo
```

2. 生成 Xcode 项目：
```bash
xcodegen generate
```

3. 打开项目：
```bash
open XMvideo.xcodeproj
```

4. 在 Xcode 中构建并运行（⌘R）

## 使用方法

1. **启动应用**：应用会在菜单栏显示一个视频图标
2. **添加文件**：
   - 点击菜单栏图标打开主界面
   - 拖拽视频文件或文件夹到界面中
3. **配置选项**：点击设置按钮选择压缩配置和高级选项
4. **开始压缩**：点击"开始"按钮
5. **查看进度**：实时查看压缩进度、速度和文件大小变化
6. **查看历史**：点击历史按钮查看压缩记录

## 压缩配置说明

### 默认配置
- CRF: 23
- Preset: veryslow
- GOP: 600
- 适合大多数场景，平衡质量和文件大小

### 高质量配置
- CRF: 18
- Preset: veryslow
- GOP: 600
- 高质量输出，文件较大

### 快速配置
- CRF: 28
- Preset: fast
- GOP: 300
- 快速处理，质量略低

### 极致压缩配置
- CRF: 32
- Preset: veryslow
- GOP: 600
- 最小文件大小，质量较低

## 支持的视频格式

- MP4
- MOV
- AVI
- MKV
- FLV
- WMV
- M4V

## 技术栈

- **Swift + SwiftUI**：原生 macOS 应用开发
- **AppKit**：菜单栏集成
- **FFmpeg**：视频处理引擎
- **VideoToolbox**：硬件加速
- **Combine**：响应式编程

## 项目结构

```
XMvideo/
├── XMvideo/
│   ├── Models/              # 数据模型
│   │   ├── CompressionTask.swift
│   │   ├── CompressionProfile.swift
│   │   ├── CompressionOptions.swift
│   │   ├── CompressionProgress.swift
│   │   ├── VideoMetadata.swift
│   │   └── HistoryRecord.swift
│   ├── Views/               # SwiftUI 视图
│   │   ├── ContentView.swift
│   │   ├── TaskListView.swift
│   │   ├── HistoryView.swift
│   │   └── SettingsView.swift
│   ├── Services/            # 业务逻辑
│   │   ├── TaskManager.swift
│   │   ├── CompressionEngine.swift
│   │   ├── ProgressMonitor.swift
│   │   ├── ConfigManager.swift
│   │   └── HistoryStore.swift
│   ├── Utilities/           # 工具类
│   │   ├── FFmpegWrapper.swift
│   │   └── ErrorHandler.swift
│   ├── AppDelegate.swift    # 应用委托
│   └── XMvideoApp.swift     # 应用入口
├── project.yml              # xcodegen 配置
└── README.md
```

## 常见问题

### FFmpeg 未安装
如果应用提示 FFmpeg 未安装，请使用 Homebrew 安装：
```bash
brew install ffmpeg
```

### 无法读取视频信息
确保视频文件未被占用，且格式受支持。

### 压缩失败
查看应用日志文件：
```bash
~/Library/Application Support/XMvideo/xmvideo.log
```

### 磁盘空间不足
确保输出目录有足够的可用空间。

### 设置页面闪退
已在最新版本修复。确保使用最新代码。

## 更新日志

### v1.0.0 (2026-02-09)
- ✅ 初始版本发布
- ✅ 菜单栏集成
- ✅ 四种压缩配置
- ✅ 文件大小显示
- ✅ 优化的设置页面 UI
- ✅ 修复设置页面闪退问题
- ✅ 改进压缩配置点击区域
- ✅ 优化输出设置布局

## 许可证

本项目采用开源许可证。

## 致谢

- **FFmpeg**：强大的音视频处理工具
- **reminders-menubar**：菜单栏应用架构参考
- **VideoSlim**：视频压缩逻辑参考

---

祝使用愉快！🎬

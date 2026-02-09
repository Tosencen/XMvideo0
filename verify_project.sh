#!/bin/bash

echo "🔍 验证 XMvideo 项目..."
echo ""

# Check if xcodegen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "❌ xcodegen 未安装"
    echo "   请运行: brew install xcodegen"
    exit 1
fi
echo "✅ xcodegen 已安装"

# Check if FFmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "⚠️  FFmpeg 未安装（运行时需要）"
    echo "   请运行: brew install ffmpeg"
else
    echo "✅ FFmpeg 已安装"
fi

# Check project structure
echo ""
echo "📁 检查项目结构..."

required_files=(
    "project.yml"
    "XMvideo/XMvideoApp.swift"
    "XMvideo/AppDelegate.swift"
    "XMvideo/Info.plist"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file 缺失"
    fi
done

# Check Models
echo ""
echo "📦 检查数据模型..."
models=(
    "XMvideo/Models/CompressionTask.swift"
    "XMvideo/Models/CompressionProfile.swift"
    "XMvideo/Models/CompressionOptions.swift"
    "XMvideo/Models/CompressionProgress.swift"
    "XMvideo/Models/VideoMetadata.swift"
    "XMvideo/Models/HistoryRecord.swift"
)

for model in "${models[@]}"; do
    if [ -f "$model" ]; then
        echo "✅ $(basename $model)"
    else
        echo "❌ $(basename $model) 缺失"
    fi
done

# Check Views
echo ""
echo "🎨 检查视图组件..."
views=(
    "XMvideo/Views/ContentView.swift"
    "XMvideo/Views/TaskListView.swift"
    "XMvideo/Views/HistoryView.swift"
    "XMvideo/Views/SettingsView.swift"
)

for view in "${views[@]}"; do
    if [ -f "$view" ]; then
        echo "✅ $(basename $view)"
    else
        echo "❌ $(basename $view) 缺失"
    fi
done

# Check Services
echo ""
echo "⚙️  检查服务类..."
services=(
    "XMvideo/Services/TaskManager.swift"
    "XMvideo/Services/CompressionEngine.swift"
    "XMvideo/Services/ProgressMonitor.swift"
    "XMvideo/Services/ConfigManager.swift"
    "XMvideo/Services/HistoryStore.swift"
)

for service in "${services[@]}"; do
    if [ -f "$service" ]; then
        echo "✅ $(basename $service)"
    else
        echo "❌ $(basename $service) 缺失"
    fi
done

# Check Utilities
echo ""
echo "🔧 检查工具类..."
utilities=(
    "XMvideo/Utilities/FFmpegWrapper.swift"
    "XMvideo/Utilities/ErrorHandler.swift"
)

for utility in "${utilities[@]}"; do
    if [ -f "$utility" ]; then
        echo "✅ $(basename $utility)"
    else
        echo "❌ $(basename $utility) 缺失"
    fi
done

# Generate Xcode project
echo ""
echo "🔨 生成 Xcode 项目..."
xcodegen generate

if [ $? -eq 0 ]; then
    echo "✅ Xcode 项目生成成功"
else
    echo "❌ Xcode 项目生成失败"
    exit 1
fi

# Check if project file exists
if [ -f "XMvideo.xcodeproj/project.pbxproj" ]; then
    echo "✅ XMvideo.xcodeproj 已创建"
else
    echo "❌ XMvideo.xcodeproj 创建失败"
    exit 1
fi

echo ""
echo "🎉 项目验证完成！"
echo ""
echo "下一步："
echo "1. 确保已安装 FFmpeg: brew install ffmpeg"
echo "2. 打开项目: open XMvideo.xcodeproj"
echo "3. 在 Xcode 中按 ⌘R 运行"
echo ""

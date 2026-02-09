# 视频压缩问题修复说明

## 问题描述
原始实现导致压缩后的视频文件反而变大了。

## 根本原因
对比 VideoSlim 的实现后发现，原始的 FFmpeg 参数配置不完整，缺少了很多关键的压缩优化参数。

## 修复内容

### 1. FFmpeg 参数优化 (FFmpegWrapper.swift)

#### 添加的关键参数：

**运动估计优化**
- `-me_method umh`: 使用 UMH (Uneven Multi-Hexagon) 运动估计算法，提供更好的压缩效率

**场景检测**
- `-sc_threshold 60`: 场景切换阈值，优化关键帧插入

**B帧策略**
- `-b_strategy 1`: B帧决策策略，提高压缩效率

**量化参数**
- `-qcomp 0.5`: 量化曲线压缩，平衡质量和文件大小
- `-psy-rd 0.3:0`: 心理视觉率失真优化
- `-aq-mode 2`: 自适应量化模式
- `-aq-strength 0.8`: 自适应量化强度

**音频处理**
- 将音频从 `-c:a copy` 改为 `-c:a aac -b:a 128k`
- 重新编码音频为 AAC 格式，128kbps 码率
- 这样可以确保音频也被压缩，而不是直接复制

**流映射**
- `-map 0:`: 映射所有流（视频、音频、字幕等）

### 2. 压缩配置优化 (CompressionProfile.swift)

#### 更新的配置参数：

**默认配置**
```swift
// 之前
crf: 23, preset: "medium", gop: 250, bframes: 3, refs: 3

// 现在（参考 VideoSlim）
crf: 23, preset: "veryslow", gop: 600, bframes: 3, refs: 4
```

**快速配置**
```swift
// 之前
crf: 28, preset: "fast", gop: 250, bframes: 2, refs: 2

// 现在
crf: 26, preset: "medium", gop: 250, bframes: 2, refs: 3
```

**高质量配置**
```swift
// 之前
crf: 18, preset: "slow", gop: 250, bframes: 4, refs: 4

// 现在
crf: 20, preset: "veryslow", gop: 600, bframes: 4, refs: 5
```

### 3. 参数说明

**CRF (Constant Rate Factor)**
- 范围：0-51，越小质量越好
- 推荐：18-28
- 23 是默认值，提供良好的质量/大小平衡

**Preset (编码速度)**
- ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
- 越慢压缩效率越高（文件越小）
- veryslow 提供最佳压缩效率

**GOP (Group of Pictures)**
- 关键帧间隔
- 600 = 约 20 秒（30fps 视频）
- 更大的 GOP 可以提高压缩效率

**B-frames (双向预测帧)**
- 范围：0-16
- 3-4 是常用值
- 更多 B 帧可以提高压缩效率

**Refs (参考帧数量)**
- 范围：1-16
- 4-5 是常用值
- 更多参考帧可以提高质量，但会增加编码时间

## VideoSlim 的配置对比

VideoSlim 默认配置：
```json
{
    "crf": 23.5,
    "preset": "veryslow",
    "I": 600,
    "r": 4,
    "b": 3,
    "opencl_acceleration": false
}
```

XMvideo 新的默认配置：
```swift
crf: 23, 
preset: "veryslow", 
gop: 600, 
bframes: 3, 
refs: 4
```

基本一致！

## 测试建议

1. **测试不同配置**
   - 默认配置：平衡质量和速度
   - 快速配置：快速处理，适合批量
   - 高质量配置：最佳质量，处理时间长

2. **验证压缩效果**
   - 检查输出文件大小是否小于原始文件
   - 播放视频检查质量是否可接受
   - 对比不同配置的效果

3. **性能考虑**
   - veryslow preset 会显著增加处理时间
   - 对于大文件或批量处理，可以考虑使用 medium 或 slow preset

## 预期效果

使用新的配置后，应该能够：
- ✅ 显著减小视频文件大小（通常可以减小 30-70%）
- ✅ 保持良好的视频质量
- ✅ 音频也会被压缩（AAC 128kbps）
- ⚠️ 处理时间会增加（veryslow preset）

## 下一步

1. 重新测试压缩功能
2. 验证文件大小确实减小
3. 检查视频质量是否满意
4. 如果需要更快的处理速度，可以在设置中调整 preset

---

**修复完成时间**: 2026年2月9日 16:42

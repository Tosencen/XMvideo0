import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyStore = HistoryStore.shared
    @State private var showingClearAlert = false
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            topToolbar
            
            Divider()
            
            if historyStore.records.isEmpty {
                emptyState
            } else {
                // Statistics header
                statisticsHeader
                
                Divider()
                
                // History list
                historyList
                
                Divider()
                
                // Clear button
                clearButton
            }
        }
    }
    
    private var topToolbar: some View {
        HStack {
            Button(action: {
                selectedTab = 0
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
            }
            
            Spacer()
            
            Text("历史记录")
                .font(.headline)
            
            Spacer()
            
            // Placeholder for symmetry
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
            }
            .opacity(0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无历史记录")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("完成压缩后会显示在这里")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var statisticsHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                StatisticItem(
                    title: "总节省",
                    value: ByteCountFormatter.string(fromByteCount: historyStore.totalSavedSize, countStyle: .file),
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                StatisticItem(
                    title: "平均压缩率",
                    value: String(format: "%.1f%%", historyStore.averageCompressionRatio * 100),
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatisticItem(
                    title: "处理文件",
                    value: "\(historyStore.records.count)",
                    icon: "doc.fill",
                    color: .orange
                )
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(historyStore.records) { record in
                    HistoryItemView(record: record)
                }
            }
            .padding()
        }
    }
    
    private var clearButton: some View {
        HStack {
            Spacer()
            
            Button("清空历史") {
                showingClearAlert = true
            }
            .alert(isPresented: $showingClearAlert) {
                Alert(
                    title: Text("清空历史记录"),
                    message: Text("确定要清空所有历史记录吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("清空")) {
                        historyStore.clearAll()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
        .padding()
    }
}

struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistoryItemView: View {
    let record: HistoryRecord
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(URL(fileURLWithPath: record.sourceFilePath).lastPathComponent)
                        .font(.system(.body, design: .default))
                        .lineLimit(1)
                    
                    Text(record.timestampString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(record.savedSizeString)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Text(record.compressionRatioString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    isExpanded.toggle()
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    DetailRow(label: "原始大小", value: record.originalSizeString)
                    DetailRow(label: "压缩后", value: record.compressedSizeString)
                    DetailRow(label: "配置", value: record.profile)
                    DetailRow(label: "输出路径", value: record.outputFilePath)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .lineLimit(1)
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(selectedTab: .constant(1))
            .frame(width: 400, height: 500)
    }
}

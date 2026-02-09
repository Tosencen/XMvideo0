import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject private var taskManager = TaskManager.shared
    @ObservedObject private var configManager = ConfigManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Content based on selected tab
            Group {
                switch selectedTab {
                case 0:
                    TaskListView(selectedTab: $selectedTab)
                case 1:
                    HistoryView(selectedTab: $selectedTab)
                case 2:
                    SettingsView(selectedTab: $selectedTab)
                default:
                    TaskListView(selectedTab: $selectedTab)
                }
            }
        }
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import Cocoa
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate!
    
    private var didCloseCancellationToken: AnyCancellable?
    private var didCloseEventDate = Date.distantPast
    
    let popover = NSPopover()
    lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    var contentViewController: NSViewController {
        let contentView = ContentView()
        return NSHostingController(rootView: contentView)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // Set application activation policy to accessory (hide from Dock)
        NSApp.setActivationPolicy(.accessory)
        
        configurePopover()
        configureMenuBarButton()
        configureDidCloseNotification()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cancel all running tasks
        let taskManager = TaskManager.shared
        if taskManager.isProcessing {
            taskManager.cancelAllTasks()
        }
        
        // Save history records
        let historyStore = HistoryStore.shared
        historyStore.saveToDisk()
        
        // Save configuration
        let configManager = ConfigManager.shared
        configManager.savePreferences()
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let taskManager = TaskManager.shared
        
        // If tasks are running, ask for confirmation
        if taskManager.isProcessing {
            let alert = NSAlert()
            alert.messageText = "正在处理视频"
            alert.informativeText = "当前有视频正在压缩，确定要退出吗？"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "退出")
            alert.addButton(withTitle: "取消")
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        
        return .terminateNow
    }
    
    private func configurePopover() {
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.animates = false
        popover.behavior = .transient
        popover.contentViewController = contentViewController
    }
    
    private func configureMenuBarButton() {
        if let button = statusBarItem.button {
            // Use SF Symbol for video icon
            button.image = NSImage(systemSymbolName: "video.fill", accessibilityDescription: "XMvideo")
            button.action = #selector(handleButtonClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc private func handleButtonClick() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "显示/隐藏", action: #selector(togglePopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出 XMvideo", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
        statusBarItem.menu = nil
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func configureDidCloseNotification() {
        // Handle popover close event to prevent immediate reopening
        didCloseCancellationToken = NotificationCenter.default
            .publisher(for: NSPopover.didCloseNotification, object: popover)
            .sink { [weak self] _ in
                self?.didCloseEventDate = Date()
            }
    }
    
    @objc private func togglePopover() {
        guard let button = statusBarItem.button else {
            return
        }
        
        if popover.contentViewController == nil {
            popover.contentViewController = contentViewController
        }
        
        // Check if popover was just closed to prevent immediate reopening
        if popover.isShown || didCloseEventDate.timeIntervalSinceNow > -0.01 {
            didCloseEventDate = .distantPast
            popover.performClose(button)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

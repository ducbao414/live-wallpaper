import Cocoa
import SwiftUI

class WindowManager: NSWindowController {
    static var shared: WindowManager?
    
    convenience init() {
        let contentView = NSHostingView(rootView: ContentView()) // Your SwiftUI view
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = contentView
        self.init(window: window)
        
        // Center the window on first appearance
        window.center()
        
        // Detect when the window is closed and reset shared instance
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
            WindowManager.shared = nil
        }
    }
    
    static func showWindow() {
        if let existingWindow = shared?.window {
            existingWindow.makeKeyAndOrderFront(nil) // Bring existing window to front
        } else {
            shared = WindowManager()
            shared?.window?.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

import AppKit

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a menu bar agent — no Dock icon (Info.plist LSUIElement=YES also handles this)
        NSApp.setActivationPolicy(.accessory)

        // Stand up the status bar icon, popover, and right-click menu
        statusBarController = StatusBarController()

        // Begin polling the clipboard
        ClipboardMonitor.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        ClipboardMonitor.shared.stop()
    }
}

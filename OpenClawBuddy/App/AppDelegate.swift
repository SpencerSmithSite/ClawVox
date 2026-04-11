import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Perform any post-launch setup here (e.g., restore connection state,
        // register global hotkeys, validate stored credentials).
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Re-opening the app (e.g., clicking the Dock icon) should surface the main window.
        return true
    }
}

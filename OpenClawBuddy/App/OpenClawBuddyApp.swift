import SwiftUI

@main
struct OpenClawBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar icon — primary entry point for the app
        MenuBarExtra("OpenClaw Buddy", systemImage: "waveform.circle.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        // Main chat window — opened from the menu bar
        WindowGroup("OpenClaw Buddy", id: "main") {
            MainWindowView()
        }
        .defaultSize(width: 800, height: 600)
        .windowResizability(.contentSize)

        // Settings panel (⌘,)
        Settings {
            SettingsView()
        }
    }
}

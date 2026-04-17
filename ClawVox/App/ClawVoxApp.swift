import SwiftUI

@main
struct ClawVoxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var conversationVM = ConversationViewModel()

    var body: some Scene {
        MenuBarExtra("ClawVox", systemImage: "waveform.circle.fill") {
            MenuBarView()
                .environmentObject(settingsVM)
                .environmentObject(conversationVM)
        }
        .menuBarExtraStyle(.window)

        WindowGroup("ClawVox", id: "main") {
            MainWindowView()
                .environmentObject(settingsVM)
                .environmentObject(conversationVM)
        }
        .defaultSize(width: 800, height: 600)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(settingsVM)
        }
    }
}

import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings = AppSettings()

    init() {
        // TODO: Load persisted settings from UserDefaults / Keychain
    }

    func save() {
        // TODO: Persist settings; write authToken to Keychain
    }

    func resetToDefaults() {
        settings = AppSettings()
    }
}

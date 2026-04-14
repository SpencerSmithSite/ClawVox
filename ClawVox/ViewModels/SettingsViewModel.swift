import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings = AppSettings()

    private enum UserDefaultsKeys {
        static let gatewayURL = "gatewayURL"
        static let sttProvider = "sttProvider"
        static let ttsProvider = "ttsProvider"
        static let selectedVoiceIdentifier = "selectedVoiceIdentifier"
        static let hotkey = "hotkey"
        static let orbColor = "orbColor"
    }
    private static let authTokenKeychainKey = "authToken"

    init() {
        load()
    }

    func save() {
        let s = settings
        let defaults = UserDefaults.standard
        defaults.set(s.gatewayURL, forKey: UserDefaultsKeys.gatewayURL)
        defaults.set(s.sttProvider.rawValue, forKey: UserDefaultsKeys.sttProvider)
        defaults.set(s.ttsProvider.rawValue, forKey: UserDefaultsKeys.ttsProvider)
        defaults.set(s.selectedVoiceIdentifier, forKey: UserDefaultsKeys.selectedVoiceIdentifier)
        defaults.set(s.hotkey, forKey: UserDefaultsKeys.hotkey)
        defaults.set(s.orbColor, forKey: UserDefaultsKeys.orbColor)

        if s.authToken.isEmpty {
            try? KeychainService.delete(forKey: Self.authTokenKeychainKey)
        } else {
            try? KeychainService.save(s.authToken, forKey: Self.authTokenKeychainKey)
        }
    }

    func resetToDefaults() {
        settings = AppSettings()
        save()
    }

    // MARK: - Private

    private func load() {
        let defaults = UserDefaults.standard
        var s = AppSettings()

        if let url = defaults.string(forKey: UserDefaultsKeys.gatewayURL) {
            s.gatewayURL = url
        }
        if let raw = defaults.string(forKey: UserDefaultsKeys.sttProvider),
           let provider = AppSettings.STTProvider(rawValue: raw) {
            s.sttProvider = provider
        }
        if let raw = defaults.string(forKey: UserDefaultsKeys.ttsProvider),
           let provider = AppSettings.TTSProvider(rawValue: raw) {
            s.ttsProvider = provider
        }
        if let voice = defaults.string(forKey: UserDefaultsKeys.selectedVoiceIdentifier) {
            s.selectedVoiceIdentifier = voice
        }
        if let hotkey = defaults.string(forKey: UserDefaultsKeys.hotkey) {
            s.hotkey = hotkey
        }
        if let color = defaults.string(forKey: UserDefaultsKeys.orbColor) {
            s.orbColor = color
        }
        s.authToken = (try? KeychainService.retrieve(forKey: Self.authTokenKeychainKey)) ?? ""

        settings = s
    }
}

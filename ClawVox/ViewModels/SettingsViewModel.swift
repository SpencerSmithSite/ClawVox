import Foundation
import Combine

enum APIKeyTestState: Equatable {
    case idle, testing, valid, invalid(String)
}

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
        static let openAITTSVoice        = "openAITTSVoice"
        static let elevenlabsVoiceID     = "elevenlabsVoiceID"
    }
    private static let authTokenKeychainKey        = "authToken"
    private static let openAIAPIKeyKeychainKey     = "openAIAPIKey"
    private static let elevenlabsAPIKeyKeychainKey = "elevenlabsAPIKey"
    /// Legacy Keychain key from V-05; read once during migration, then deleted.
    private static let legacyWhisperKeyKeychainKey = "whisperAPIKey"

    @Published var hasCompletedOnboarding: Bool = false
    @Published var openAIKeyTestState: APIKeyTestState = .idle
    @Published var elevenlabsKeyTestState: APIKeyTestState = .idle

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
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
        defaults.set(s.openAITTSVoice, forKey: UserDefaultsKeys.openAITTSVoice)
        defaults.set(s.elevenlabsVoiceID, forKey: UserDefaultsKeys.elevenlabsVoiceID)

        if s.authToken.isEmpty {
            try? KeychainService.delete(forKey: Self.authTokenKeychainKey)
        } else {
            try? KeychainService.save(s.authToken, forKey: Self.authTokenKeychainKey)
        }

        if s.openAIAPIKey.isEmpty {
            try? KeychainService.delete(forKey: Self.openAIAPIKeyKeychainKey)
        } else {
            try? KeychainService.save(s.openAIAPIKey, forKey: Self.openAIAPIKeyKeychainKey)
        }

        if s.elevenlabsAPIKey.isEmpty {
            try? KeychainService.delete(forKey: Self.elevenlabsAPIKeyKeychainKey)
        } else {
            try? KeychainService.save(s.elevenlabsAPIKey, forKey: Self.elevenlabsAPIKeyKeychainKey)
        }
    }

    func testOpenAIKey() {
        guard !settings.openAIAPIKey.isEmpty else { return }
        openAIKeyTestState = .testing
        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
                request.setValue("Bearer \(settings.openAIAPIKey)", forHTTPHeaderField: "Authorization")
                let (_, response) = try await URLSession.shared.data(for: request)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                openAIKeyTestState = code == 200 ? .valid : .invalid("HTTP \(code)")
            } catch {
                openAIKeyTestState = .invalid(error.localizedDescription)
            }
        }
    }

    func testElevenLabsKey() {
        guard !settings.elevenlabsAPIKey.isEmpty else { return }
        elevenlabsKeyTestState = .testing
        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/user")!)
                request.setValue(settings.elevenlabsAPIKey, forHTTPHeaderField: "xi-api-key")
                let (_, response) = try await URLSession.shared.data(for: request)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                elevenlabsKeyTestState = code == 200 ? .valid : .invalid("HTTP \(code)")
            } catch {
                elevenlabsKeyTestState = .invalid(error.localizedDescription)
            }
        }
    }

    func completeOnboarding() {
        save()
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
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
        if let voice = defaults.string(forKey: UserDefaultsKeys.openAITTSVoice) {
            s.openAITTSVoice = voice
        }
        if let voiceID = defaults.string(forKey: UserDefaultsKeys.elevenlabsVoiceID) {
            s.elevenlabsVoiceID = voiceID
        }

        s.authToken = (try? KeychainService.retrieve(forKey: Self.authTokenKeychainKey)) ?? ""

        s.elevenlabsAPIKey = (try? KeychainService.retrieve(forKey: Self.elevenlabsAPIKeyKeychainKey)) ?? ""

        // Load OpenAI API key; migrate from legacy "whisperAPIKey" if present.
        if let key = try? KeychainService.retrieve(forKey: Self.openAIAPIKeyKeychainKey), !key.isEmpty {
            s.openAIAPIKey = key
        } else if let legacy = try? KeychainService.retrieve(forKey: Self.legacyWhisperKeyKeychainKey),
                  !legacy.isEmpty {
            s.openAIAPIKey = legacy
            try? KeychainService.save(legacy, forKey: Self.openAIAPIKeyKeychainKey)
            try? KeychainService.delete(forKey: Self.legacyWhisperKeyKeychainKey)
        }

        settings = s
    }
}

import Foundation

struct AppSettings: Codable, Equatable {
    var gatewayURL: String = "http://localhost:18789"
    var authToken: String = ""
    var sttProvider: STTProvider = .apple
    var ttsProvider: TTSProvider = .apple
    var selectedVoiceIdentifier: String = ""
    var hotkey: String = ""
    var orbColor: String = "#00CFFF"
    /// OpenAI API key for Whisper STT — stored in Keychain, not UserDefaults.
    var whisperAPIKey: String = ""

    enum STTProvider: String, Codable, CaseIterable {
        case apple = "Apple Speech (Local)"
        case whisper = "OpenAI Whisper"
    }

    enum TTSProvider: String, Codable, CaseIterable {
        case apple = "Apple TTS (Local)"
        case elevenlabs = "ElevenLabs"
        case openai = "OpenAI TTS"
    }
}

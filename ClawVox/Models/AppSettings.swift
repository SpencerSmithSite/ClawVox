import Foundation

struct AppSettings: Codable, Equatable {
    var gatewayURL: String = "http://localhost:18789"
    var authToken: String = ""
    var sttProvider: STTProvider = .apple
    var ttsProvider: TTSProvider = .apple
    var selectedVoiceIdentifier: String = ""
    var hotkey: String = ""
    var orbColor: String = "#00CFFF"
    /// Shared OpenAI API key — used for Whisper STT and OpenAI TTS.
    /// Stored in Keychain, never in UserDefaults.
    var openAIAPIKey: String = ""
    /// Voice identifier for OpenAI TTS (alloy, echo, fable, onyx, nova, shimmer).
    var openAITTSVoice: String = "alloy"

    enum STTProvider: String, Codable, CaseIterable {
        case apple = "Apple Speech (Local)"
        case whisper = "OpenAI Whisper"
    }

    enum TTSProvider: String, Codable, CaseIterable {
        case apple = "Apple TTS (Local)"
        case elevenlabs = "ElevenLabs"
        case openai = "OpenAI TTS"
    }

    /// All available voices for the OpenAI TTS API.
    static let openAIVoices = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]
}

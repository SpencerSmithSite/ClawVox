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
    /// ElevenLabs API key — stored in Keychain, never in UserDefaults.
    var elevenlabsAPIKey: String = ""
    /// ElevenLabs voice ID. Defaults to Rachel.
    var elevenlabsVoiceID: String = "21m00Tcm4TlvDq8ikWAM"

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

    /// A curated list of popular ElevenLabs pre-made voices.
    struct ElevenLabsVoice: Identifiable {
        let id: String
        let name: String
    }

    static let elevenlabsVoices: [ElevenLabsVoice] = [
        .init(id: "21m00Tcm4TlvDq8ikWAM", name: "Rachel"),
        .init(id: "AZnzlk1XvdvUeBnXmlld", name: "Domi"),
        .init(id: "EXAVITQu4vr4xnSDxMaL", name: "Bella"),
        .init(id: "ErXwobaYiN019PkySvjV", name: "Antoni"),
        .init(id: "MF3mGyEYCl7XYWbV9V6O", name: "Elli"),
        .init(id: "TxGEqnHWrfWFTfGW9XjX", name: "Josh"),
        .init(id: "VR6AewLTigWG4xSOukaG", name: "Arnold"),
        .init(id: "pNInz6obpgDQGcFmaJgB", name: "Adam"),
        .init(id: "yoZ06aMxZJJ28mfd3POQ", name: "Sam"),
    ]
}

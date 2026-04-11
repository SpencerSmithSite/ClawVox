import Foundation
import AVFoundation

/// Text-to-speech service using Apple's AVSpeechSynthesizer.
@MainActor
final class TTSService: ObservableObject {
    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private var selectedVoice: AVSpeechSynthesisVoice?

    func configure(voiceIdentifier: String) {
        selectedVoice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)
            ?? AVSpeechSynthesisVoice(language: Locale.current.identifier)
    }

    func speak(_ text: String) {
        // TODO: Build AVSpeechUtterance, set voice, call synthesizer.speak(_:)
        isSpeaking = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    /// Returns all available macOS TTS voices.
    static func availableVoices() -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
    }
}

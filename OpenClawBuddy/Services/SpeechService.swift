import Foundation
import Speech

/// Manages speech-to-text transcription using Apple's on-device Speech framework.
@MainActor
final class SpeechService: ObservableObject {
    @Published var transcript: String = ""
    @Published var isListening: Bool = false

    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: .current)

    /// Request speech recognition authorization from the user.
    func requestAuthorization() async -> Bool {
        // TODO: SFSpeechRecognizer.requestAuthorization and return result
        return false
    }

    /// Begin capturing microphone audio and streaming transcription.
    func startListening() {
        // TODO: Set up AVAudioEngine + SFSpeechAudioBufferRecognitionRequest
        isListening = true
    }

    /// Stop capturing and finalize the transcript.
    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }
}

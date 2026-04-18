import Foundation
import Speech
import AVFoundation
import Combine

/// Manages speech-to-text transcription using Apple's on-device Speech framework.
@MainActor
final class SpeechService: ObservableObject {
    @Published var transcript: String = ""
    @Published var isListening: Bool = false

    /// Fires once with the final recognized string when recognition ends naturally.
    let finalTranscript = PassthroughSubject<String, Never>()

    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let recognizer = SFSpeechRecognizer(locale: .current)
    private let audioEngine = AVAudioEngine()
    private var tapInstalled = false

    /// Request speech recognition authorization from the user.
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// Begin capturing microphone audio and streaming transcription.
    func startListening() {
        guard let recognizer, recognizer.isAvailable else { return }
        stopListening()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.finalTranscript.send(result.bestTranscription.formattedString)
                        self.stopListening()
                        return
                    }
                }
                if error != nil {
                    self.stopListening()
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        // Capture `request` directly so the tap closure avoids actor isolation issues.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        tapInstalled = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            cleanupAfterStop()
        }
    }

    /// Stop capturing and finalize the transcript.
    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        cleanupAfterStop()
    }

    private func cleanupAfterStop() {
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }
}

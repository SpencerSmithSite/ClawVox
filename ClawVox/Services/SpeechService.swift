import Foundation
import Speech
import AVFoundation
import Combine

/// Manages speech-to-text transcription using Apple's on-device Speech framework.
@MainActor
final class SpeechService: ObservableObject {
    @Published var transcript: String = ""
    @Published var isListening: Bool = false
    /// Normalised RMS level of the mic input (0.0 – 1.0). Useful for orb visualiser.
    @Published var audioLevel: Float = 0.0

    /// Fires once with the final recognised string when recognition ends naturally.
    let finalTranscript = PassthroughSubject<String, Never>()

    // MARK: - Configuration

    /// RMS amplitude below which audio is considered silence.
    private let silenceThreshold: Float = 0.015
    /// Seconds of continuous silence after speech has started before auto-stopping.
    private let silenceDuration: TimeInterval = 1.5
    /// RMS value that maps to audioLevel == 1.0 (typical loud-speech amplitude).
    private let audioLevelNorm: Float = 0.08

    // MARK: - Private state

    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private let recognizer = SFSpeechRecognizer(locale: .current)
    private let audioEngine = AVAudioEngine()
    private var tapInstalled = false

    // VAD (V-04)
    private var hasSpeechStarted = false
    private var lastActiveTime: Date = .now
    private var silenceCheckTask: Task<Void, Never>?

    // Engine configuration observer (V-03)
    private var engineConfigObserver: NSObjectProtocol?

    // MARK: - Authorization

    /// Request speech recognition authorization from the user.
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Listening lifecycle

    /// Begin capturing microphone audio and streaming transcription.
    func startListening() {
        guard let recognizer, recognizer.isAvailable else { return }
        stopListening() // Clean up any previous session first.

        // V-03: Restart gracefully when audio hardware changes (headphones, etc.)
        engineConfigObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: audioEngine,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isListening else { return }
                self.restartListening()
            }
        }

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

        // Reset VAD state for this new session.
        hasSpeechStarted = false
        lastActiveTime = .now

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        // Capture `request` directly — avoids actor-isolation issues in the tap closure,
        // and SFSpeechAudioBufferRecognitionRequest.append(_:) is thread-safe.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            request.append(buffer)
            // V-04: compute RMS on the audio thread, then update state on the main actor.
            let rms = buffer.rms
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.audioLevel = min(rms / self.audioLevelNorm, 1.0)
                if rms > self.silenceThreshold {
                    self.hasSpeechStarted = true
                    self.lastActiveTime = .now
                }
            }
        }
        tapInstalled = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            startSilenceMonitor() // V-04
        } catch {
            cleanupAfterStop()
        }
    }

    /// Stop capturing and discard the current recognition session.
    func stopListening() {
        silenceCheckTask?.cancel()
        silenceCheckTask = nil

        if let obs = engineConfigObserver {
            NotificationCenter.default.removeObserver(obs)
            engineConfigObserver = nil
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        cleanupAfterStop()
    }

    // MARK: - Private helpers

    /// Restart after an audio hardware configuration change.
    private func restartListening() {
        stopListening()
        startListening()
    }

    // MARK: - V-04: Voice activity detection

    /// Polls every 200 ms; auto-stops and sends finalTranscript after prolonged silence.
    private func startSilenceMonitor() {
        silenceCheckTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard isListening, hasSpeechStarted else { continue }
                if Date.now.timeIntervalSince(lastActiveTime) >= silenceDuration {
                    // Capture transcript before teardown.
                    let current = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                    stopListening()
                    if !current.isEmpty {
                        finalTranscript.send(current)
                    }
                    break
                }
            }
        }
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
        hasSpeechStarted = false
        audioLevel = 0.0
        isListening = false
    }
}

// AVAudioPCMBuffer.rms is defined in Utilities/Extensions.swift

// MARK: - STTServiceProtocol

extension SpeechService: STTServiceProtocol {
    var isListeningPublisher: AnyPublisher<Bool, Never> { $isListening.eraseToAnyPublisher() }
    var audioLevelPublisher: AnyPublisher<Float, Never> { $audioLevel.eraseToAnyPublisher() }
}

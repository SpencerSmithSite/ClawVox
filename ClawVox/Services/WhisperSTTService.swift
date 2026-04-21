import Foundation
import AVFoundation
import Combine

/// Records microphone audio, applies VAD silence detection, then transcribes via
/// the OpenAI Whisper API (`/v1/audio/transcriptions`).
///
/// Use `configure(apiKey:)` before calling `startListening()`.
@MainActor
final class WhisperSTTService: ObservableObject {
    @Published var isListening: Bool = false
    @Published var isTranscribing: Bool = false
    /// Normalised RMS level of the mic input (0.0 – 1.0). Useful for orb visualiser.
    @Published var audioLevel: Float = 0.0

    /// Fires with the transcribed text once the Whisper API call completes.
    let finalTranscript = PassthroughSubject<String, Never>()

    // MARK: - Configuration

    private let silenceThreshold: Float = 0.015
    private let silenceDuration: TimeInterval = 1.5
    private let audioLevelNorm: Float = 0.08
    private let whisperEndpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    private var apiKey: String = ""

    // MARK: - Audio state

    private let audioEngine = AVAudioEngine()
    private var tapInstalled = false
    private var recordedBuffers: [AVAudioPCMBuffer] = []
    private var recordingFormat: AVAudioFormat?

    // VAD state
    private var hasSpeechStarted = false
    private var lastActiveTime: Date = .now
    private var silenceCheckTask: Task<Void, Never>?

    // MARK: - Public interface

    func configure(apiKey: String) {
        self.apiKey = apiKey
    }

    func startListening() {
        guard !apiKey.isEmpty else { return }
        stopListening()

        recordedBuffers = []
        hasSpeechStarted = false
        lastActiveTime = .now

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        recordingFormat = format

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            // Copy buffer before handing off — the tap reuses the underlying memory.
            if let copy = buffer.copy() as? AVAudioPCMBuffer {
                Task { @MainActor [weak self] in self?.recordedBuffers.append(copy) }
            }
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
            startSilenceMonitor()
        } catch {
            cleanupAudio()
        }
    }

    /// Stops recording and fires off a Whisper API transcription in the background.
    func stopListening() {
        silenceCheckTask?.cancel()
        silenceCheckTask = nil

        let buffersSnapshot = recordedBuffers
        let formatSnapshot = recordingFormat
        cleanupAudio()

        Task { await performTranscription(buffers: buffersSnapshot, format: formatSnapshot) }
    }

    // MARK: - VAD

    private func startSilenceMonitor() {
        silenceCheckTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard isListening, hasSpeechStarted else { continue }
                if Date.now.timeIntervalSince(lastActiveTime) >= silenceDuration {
                    stopListening()
                    break
                }
            }
        }
    }

    // MARK: - Audio teardown

    private func cleanupAudio() {
        if audioEngine.isRunning { audioEngine.stop() }
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        audioLevel = 0.0
        isListening = false
    }

    // MARK: - Transcription

    private func performTranscription(buffers: [AVAudioPCMBuffer], format: AVAudioFormat?) async {
        guard !buffers.isEmpty, let format, !apiKey.isEmpty else { return }

        isTranscribing = true
        defer { isTranscribing = false }

        do {
            let wav = try encodeToWAV(buffers: buffers, format: format)
            let text = try await callWhisperAPI(wavData: wav)
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                finalTranscript.send(trimmed)
            }
        } catch {
#if DEBUG
            print("[WhisperSTTService] Transcription error: \(error)")
#endif
        }
    }

    // MARK: - WAV encoding

    /// Encodes accumulated PCM buffers as a mono 16-bit WAV `Data` blob.
    private func encodeToWAV(buffers: [AVAudioPCMBuffer], format: AVAudioFormat) throws -> Data {
        // Collect all float samples from channel 0.
        var samples: [Float] = []
        for buffer in buffers {
            guard let channelData = buffer.floatChannelData else { continue }
            let count = Int(buffer.frameLength)
            samples.append(contentsOf: UnsafeBufferPointer(start: channelData[0], count: count))
        }
        guard !samples.isEmpty else { throw WhisperError.noAudioData }

        // Convert float32 → int16
        let int16Samples = samples.map { Int16(max(-1.0, min(1.0, $0)) * 32_767) }

        let sampleRate    = UInt32(format.sampleRate)
        let numChannels   = UInt16(1)
        let bitsPerSample = UInt16(16)
        let byteRate      = sampleRate * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        let blockAlign    = numChannels * (bitsPerSample / 8)
        let dataSize      = UInt32(int16Samples.count * 2)

        var wav = Data()
        wav.append(contentsOf: "RIFF".utf8)
        wav.appendLE(UInt32(36 + dataSize))
        wav.append(contentsOf: "WAVE".utf8)
        wav.append(contentsOf: "fmt ".utf8)
        wav.appendLE(UInt32(16))        // chunk size
        wav.appendLE(UInt16(1))         // PCM = 1
        wav.appendLE(numChannels)
        wav.appendLE(sampleRate)
        wav.appendLE(byteRate)
        wav.appendLE(blockAlign)
        wav.appendLE(bitsPerSample)
        wav.append(contentsOf: "data".utf8)
        wav.appendLE(dataSize)
        for sample in int16Samples { wav.appendLE(sample) }

        return wav
    }

    // MARK: - Whisper API

    private func callWhisperAPI(wavData: Data) async throws -> String {
        var request = URLRequest(url: whisperEndpoint)
        request.httpMethod = "POST"

        let boundary = "WhisperBoundary-\(UUID().uuidString)"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func field(_ name: String, value: String) {
            body.append(contentsOf: "--\(boundary)\r\n".utf8)
            body.append(contentsOf: "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8)
            body.append(contentsOf: "\(value)\r\n".utf8)
        }

        // Audio file
        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".utf8)
        body.append(contentsOf: "Content-Type: audio/wav\r\n\r\n".utf8)
        body.append(wavData)
        body.append(contentsOf: "\r\n".utf8)

        field("model", value: "whisper-1")
        field("response_format", value: "text")
        body.append(contentsOf: "--\(boundary)--\r\n".utf8)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WhisperError.apiError(code)
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

// MARK: - STTServiceProtocol

extension WhisperSTTService: STTServiceProtocol {
    var isListeningPublisher: AnyPublisher<Bool, Never> { $isListening.eraseToAnyPublisher() }
    var audioLevelPublisher: AnyPublisher<Float, Never> { $audioLevel.eraseToAnyPublisher() }
}

// MARK: - Errors

enum WhisperError: LocalizedError {
    case noAudioData
    case apiError(Int)

    var errorDescription: String? {
        switch self {
        case .noAudioData:     return "No audio was recorded."
        case .apiError(let c): return "Whisper API returned HTTP \(c)."
        }
    }
}

// MARK: - Data little-endian helpers

private extension Data {
    /// Append a fixed-width integer as little-endian bytes.
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        let le = value.littleEndian
        for i in 0..<MemoryLayout<T>.size {
            append(UInt8(truncatingIfNeeded: le >> (i * 8)))
        }
    }
}

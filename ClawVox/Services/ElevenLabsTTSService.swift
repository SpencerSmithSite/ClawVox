import Foundation
import AVFoundation
import Combine

/// Text-to-speech via the ElevenLabs `/v1/text-to-speech/{voice_id}` API.
///
/// Downloads the full MP3 response then plays it with `AVAudioPlayer`.
/// Call `configure(apiKey:voiceID:)` once before using `speak(_:)`.
@MainActor
final class ElevenLabsTTSService: NSObject, ObservableObject {
    @Published var isSpeaking: Bool = false

    private let baseURL = URL(string: "https://api.elevenlabs.io/v1/text-to-speech")!
    private var apiKey: String = ""
    private var voiceID: String = "21m00Tcm4TlvDq8ikWAM"  // Rachel

    private var audioPlayer: AVAudioPlayer?
    private var speakTask: Task<Void, Never>?

    override init() {
        super.init()
    }

    // MARK: - Public interface

    func configure(apiKey: String, voiceID: String) {
        self.apiKey = apiKey
        self.voiceID = voiceID.isEmpty ? "21m00Tcm4TlvDq8ikWAM" : voiceID
    }

    func speak(_ text: String) {
        guard !apiKey.isEmpty, !text.isEmpty else { return }
        speakTask?.cancel()
        audioPlayer?.stop()
        audioPlayer = nil
        speakTask = Task { await performTTS(text: text) }
    }

    func stop() {
        speakTask?.cancel()
        speakTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }

    // MARK: - Private

    private func performTTS(text: String) async {
        isSpeaking = true
        defer {
            if !Task.isCancelled { isSpeaking = false }
        }

        do {
            let data = try await fetchAudio(text: text)
            guard !Task.isCancelled else { return }
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            audioPlayer = player
            player.play()
            // isSpeaking stays true until audioPlayerDidFinishPlaying fires.
        } catch {
#if DEBUG
            print("[ElevenLabsTTSService] Error: \(error)")
#endif
            isSpeaking = false
        }
    }

    private func fetchAudio(text: String) async throws -> Data {
        let url = baseURL.appendingPathComponent(voiceID)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ElevenLabsError.apiError(code)
        }
        return data
    }
}

// MARK: - TTSServiceProtocol

extension ElevenLabsTTSService: TTSServiceProtocol {
    var isSpeakingPublisher: AnyPublisher<Bool, Never> { $isSpeaking.eraseToAnyPublisher() }
}

// MARK: - AVAudioPlayerDelegate

extension ElevenLabsTTSService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.isSpeaking = false }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in self.isSpeaking = false }
    }
}

// MARK: - Errors

enum ElevenLabsError: LocalizedError {
    case apiError(Int)

    var errorDescription: String? {
        switch self {
        case .apiError(let code): return "ElevenLabs API returned HTTP \(code)."
        }
    }
}

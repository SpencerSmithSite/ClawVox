import Foundation
import AVFoundation

/// Text-to-speech via the OpenAI `/v1/audio/speech` API.
///
/// Downloads the full audio response then plays it with `AVAudioPlayer`.
/// Call `configure(apiKey:voice:)` once before using `speak(_:)`.
@MainActor
final class OpenAITTSService: NSObject, ObservableObject {
    @Published var isSpeaking: Bool = false

    private let endpoint = URL(string: "https://api.openai.com/v1/audio/speech")!
    private var apiKey: String = ""
    private var voice: String = "alloy"

    private var audioPlayer: AVAudioPlayer?
    private var speakTask: Task<Void, Never>?

    override init() {
        super.init()
    }

    // MARK: - Public interface

    func configure(apiKey: String, voice: String) {
        self.apiKey = apiKey
        self.voice = voice.isEmpty ? "alloy" : voice
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
            // isSpeaking stays true until delegate fires audioPlayerDidFinishPlaying.
        } catch {
#if DEBUG
            print("[OpenAITTSService] Error: \(error)")
#endif
            isSpeaking = false
        }
    }

    private func fetchAudio(text: String) async throws -> Data {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw OpenAITTSError.apiError(code)
        }
        return data
    }
}

// MARK: - AVAudioPlayerDelegate

extension OpenAITTSService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.isSpeaking = false }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in self.isSpeaking = false }
    }
}

// MARK: - Errors

enum OpenAITTSError: LocalizedError {
    case apiError(Int)

    var errorDescription: String? {
        switch self {
        case .apiError(let code): return "OpenAI TTS API returned HTTP \(code)."
        }
    }
}

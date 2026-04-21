import Combine

/// Common interface for all text-to-speech backends.
///
/// Conform new TTS providers (e.g. ElevenLabs) to this protocol so that
/// `ConversationViewModel` can dispatch through `activeTTSService` without
/// knowing the concrete implementation.
@MainActor
protocol TTSServiceProtocol: AnyObject {
    /// `true` while audio is being synthesised or played back.
    var isSpeaking: Bool { get }
    /// Publisher that fires whenever `isSpeaking` changes.
    var isSpeakingPublisher: AnyPublisher<Bool, Never> { get }
    /// Begin synthesising and playing `text`.
    func speak(_ text: String)
    /// Immediately stop any in-progress speech.
    func stop()
}

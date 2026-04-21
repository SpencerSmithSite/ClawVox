import Combine

/// Common interface for all speech-to-text backends.
///
/// Conform new STT providers to this protocol so that `ConversationViewModel`
/// can dispatch through `activeSTTService` without knowing the concrete type.
@MainActor
protocol STTServiceProtocol: AnyObject {
    /// `true` while the microphone is being captured.
    var isListening: Bool { get }
    /// Publisher that fires whenever `isListening` changes.
    var isListeningPublisher: AnyPublisher<Bool, Never> { get }
    /// Normalised RMS microphone level (0.0 – 1.0).
    var audioLevel: Float { get }
    /// Publisher that fires whenever `audioLevel` changes.
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
    /// Fires once with the final transcript when recognition ends.
    var finalTranscript: PassthroughSubject<String, Never> { get }
    /// Begin capturing and transcribing microphone audio.
    func startListening()
    /// Stop capturing audio (may fire a final transcript before stopping).
    func stopListening()
}

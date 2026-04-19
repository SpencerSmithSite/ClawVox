import SwiftUI

/// An animated orb that pulses in scale and glow based on audio state.
///
/// - Parameters:
///   - level: Normalised mic input (0–1). Wire to `ConversationViewModel.audioLevel`.
///   - isSpeaking: When true, overrides `level` with a slow breathing animation to
///     indicate TTS playback. Wire to `ConversationViewModel.isSpeaking`.
///   - color: Core/glow color. Defaults to cyan; use the user's orbColor setting.
struct OrbView: View {
    var level: Double = 0.0
    var isSpeaking: Bool = false
    var color: Color = Color(hex: "#00CFFF")

    var body: some View {
        GeometryReader { geo in
            let radius = geo.size.width / 2
            if isSpeaking {
                // Drive a continuous sine-wave breath every frame.
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    // Period ≈ 2.4 s, amplitude 0–0.65.
                    let breathLevel = (sin(t * .pi / 1.2) + 1) / 2 * 0.65
                    orbCircle(radius: radius, level: breathLevel)
                }
            } else {
                orbCircle(radius: radius, level: level)
                    .animation(.easeOut(duration: 0.08), value: level)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func orbCircle(radius: CGFloat, level: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, Color(hex: "#6B00FF"), Color.black],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .scaleEffect(1.0 + level * 0.15)
            .shadow(
                color: color.opacity(level * 0.7),
                radius: radius * 0.6 * level
            )
    }
}

#Preview {
    HStack(spacing: 32) {
        OrbView(level: 0.0).frame(width: 80, height: 80)
        OrbView(level: 0.5).frame(width: 80, height: 80)
        OrbView(level: 1.0).frame(width: 80, height: 80)
        OrbView(isSpeaking: true).frame(width: 80, height: 80)
        OrbView(isSpeaking: true, color: .green).frame(width: 80, height: 80)
    }
    .padding(40)
    .background(Color.black)
}

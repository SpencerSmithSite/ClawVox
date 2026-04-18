import SwiftUI

/// An animated orb that pulses in scale and glow based on an audio activity level.
///
/// - Parameter level: Normalised audio activity, 0.0 (idle) to 1.0 (peak).
///   Wire to `ConversationViewModel.audioLevel` while listening, or leave at 0.
struct OrbView: View {
    var level: Double = 0.0

    var body: some View {
        GeometryReader { geo in
            let radius = geo.size.width / 2
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#00CFFF"),  // cyan core
                            Color(hex: "#6B00FF"),  // purple mid
                            Color.black             // dark edge
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                // Gentle scale pulse: +15 % at peak level.
                .scaleEffect(1.0 + level * 0.15)
                // Cyan glow brightens with level.
                .shadow(
                    color: Color(hex: "#00CFFF").opacity(level * 0.7),
                    radius: radius * 0.6 * level
                )
                .animation(.easeOut(duration: 0.08), value: level)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    HStack(spacing: 32) {
        OrbView(level: 0.0).frame(width: 80, height: 80)
        OrbView(level: 0.5).frame(width: 80, height: 80)
        OrbView(level: 1.0).frame(width: 80, height: 80)
    }
    .padding(40)
    .background(Color.black)
}

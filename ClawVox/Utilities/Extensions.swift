import SwiftUI

// MARK: - Color extensions

extension Color {
    /// Initialise a Color from a CSS-style hex string, e.g. "#00CFFF".
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 0xFF)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 0xFF)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date extensions

extension Date {
    /// Formatted time string for display in chat messages.
    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - String extensions

extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

// MARK: - AVAudioPCMBuffer extensions

import AVFoundation

extension AVAudioPCMBuffer {
    /// Root-mean-square amplitude across all frames in channel 0.
    var rms: Float {
        guard let channelData = floatChannelData, frameLength > 0 else { return 0 }
        let channel = channelData[0]
        let count = Int(frameLength)
        var sumSquares: Float = 0
        for i in 0..<count {
            sumSquares += channel[i] * channel[i]
        }
        return sqrt(sumSquares / Float(count))
    }
}

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var conversationVM: ConversationViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            OrbView(level: Double(conversationVM.audioLevel))
                .frame(width: 80, height: 80)

            Text("ClawVox")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 5) {
                Circle()
                    .fill(connectionColor)
                    .frame(width: 7, height: 7)
                Text(connectionLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if case .error = conversationVM.connectionState {
                    Button(action: { conversationVM.checkConnection() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Retry connection")
                }
            }

            Spacer()

            Button("Open Chat") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#00CFFF"))
            .foregroundStyle(.black)
        }
        .padding()
        .frame(width: 320, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var connectionColor: Color {
        switch conversationVM.connectionState {
        case .connected:    return .green
        case .connecting:   return .yellow
        case .disconnected: return .gray
        case .error:        return .red
        }
    }

    private var connectionLabel: String {
        switch conversationVM.connectionState {
        case .connected:         return "Connected"
        case .connecting:        return "Connecting…"
        case .disconnected:      return "Disconnected"
        case .error(let msg):    return msg
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(ConversationViewModel())
}

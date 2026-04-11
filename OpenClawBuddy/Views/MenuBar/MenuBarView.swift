import SwiftUI

struct MenuBarView: View {
    var body: some View {
        VStack(spacing: 12) {
            OrbView()
                .frame(width: 80, height: 80)

            Text("OpenClaw Buddy")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Not connected")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .frame(width: 320, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    MenuBarView()
}

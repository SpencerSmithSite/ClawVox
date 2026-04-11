import SwiftUI

struct MainWindowView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text("OpenClaw Buddy")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .frame(width: 800, height: 600)
    }
}

#Preview {
    MainWindowView()
}

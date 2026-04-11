import SwiftUI

struct OnboardingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text("Welcome to ClawVox")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    OnboardingView()
}

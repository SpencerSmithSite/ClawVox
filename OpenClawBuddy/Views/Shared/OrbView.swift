import SwiftUI

struct OrbView: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hex: "#00CFFF"),  // cyan core
                        Color(hex: "#6B00FF"),  // purple mid
                        Color.black            // dark edge
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
            )
            .frame(width: 200, height: 200)
    }
}

#Preview {
    OrbView()
        .background(Color.black)
        .frame(width: 300, height: 300)
}

import SwiftUI

struct SettingsView: View {
    @State private var gatewayURL: String = "http://localhost:18789"
    @State private var authToken: String = ""

    var body: some View {
        Form {
            Section("Connection") {
                TextField("Gateway URL", text: $gatewayURL)
                    .textFieldStyle(.roundedBorder)

                SecureField("Auth Token", text: $authToken)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 480, height: 280)
    }
}

#Preview {
    SettingsView()
}

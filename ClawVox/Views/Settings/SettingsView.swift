import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel

    var body: some View {
        Form {
            Section("Connection") {
                TextField("Gateway URL", text: $settingsVM.settings.gatewayURL)
                    .textFieldStyle(.roundedBorder)

                SecureField("Auth Token", text: $settingsVM.settings.authToken)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Speech-to-Text") {
                Picker("STT Provider", selection: $settingsVM.settings.sttProvider) {
                    ForEach(AppSettings.STTProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                if settingsVM.settings.sttProvider == .whisper {
                    SecureField("OpenAI API Key", text: $settingsVM.settings.whisperAPIKey)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Section("Text-to-Speech") {
                Picker("TTS Provider", selection: $settingsVM.settings.ttsProvider) {
                    ForEach(AppSettings.TTSProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
            }

            Section("Appearance") {
                TextField("Orb Color (hex)", text: $settingsVM.settings.orbColor)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Hotkey") {
                TextField("Global Hotkey", text: $settingsVM.settings.hotkey)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Reset to Defaults") {
                    settingsVM.resetToDefaults()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Save") {
                    settingsVM.save()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("s", modifiers: .command)
            }
            .padding(.top, 4)
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 480, height: 440)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
}

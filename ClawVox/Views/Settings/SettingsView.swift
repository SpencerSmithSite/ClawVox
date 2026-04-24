import SwiftUI
import AVFoundation

struct SettingsView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel

    private let appleVoices: [AVSpeechSynthesisVoice] = {
        let locale = Locale.current.language.languageCode?.identifier ?? "en"
        let all = TTSService.availableVoices()
        let matching = all.filter { $0.language.hasPrefix(locale) }
        return matching.isEmpty ? all : matching
    }()

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
                    apiKeyRow(
                        label: "OpenAI API Key",
                        key: $settingsVM.settings.openAIAPIKey,
                        testState: settingsVM.openAIKeyTestState,
                        onTest: { settingsVM.testOpenAIKey() },
                        onClear: { settingsVM.openAIKeyTestState = .idle }
                    )
                }
            }

            Section("Text-to-Speech") {
                Picker("TTS Provider", selection: $settingsVM.settings.ttsProvider) {
                    ForEach(AppSettings.TTSProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                if settingsVM.settings.ttsProvider == .apple {
                    Picker("Voice", selection: $settingsVM.settings.selectedVoiceIdentifier) {
                        Text("System Default").tag("")
                        ForEach(appleVoices, id: \.identifier) { voice in
                            Text(voiceLabel(voice)).tag(voice.identifier)
                        }
                    }
                }
                if settingsVM.settings.ttsProvider == .openai {
                    if settingsVM.settings.sttProvider != .whisper {
                        apiKeyRow(
                            label: "OpenAI API Key",
                            key: $settingsVM.settings.openAIAPIKey,
                            testState: settingsVM.openAIKeyTestState,
                            onTest: { settingsVM.testOpenAIKey() },
                            onClear: { settingsVM.openAIKeyTestState = .idle }
                        )
                    }
                    Picker("Voice", selection: $settingsVM.settings.openAITTSVoice) {
                        ForEach(AppSettings.openAIVoices, id: \.self) { voice in
                            Text(voice.capitalized).tag(voice)
                        }
                    }
                }
                if settingsVM.settings.ttsProvider == .elevenlabs {
                    apiKeyRow(
                        label: "ElevenLabs API Key",
                        key: $settingsVM.settings.elevenlabsAPIKey,
                        testState: settingsVM.elevenlabsKeyTestState,
                        onTest: { settingsVM.testElevenLabsKey() },
                        onClear: { settingsVM.elevenlabsKeyTestState = .idle }
                    )
                    Picker("Voice", selection: $settingsVM.settings.elevenlabsVoiceID) {
                        ForEach(AppSettings.elevenlabsVoices) { voice in
                            Text(voice.name).tag(voice.id)
                        }
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
        .frame(width: 480, height: 460)
    }

    @ViewBuilder
    private func apiKeyRow(
        label: String,
        key: Binding<String>,
        testState: APIKeyTestState,
        onTest: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 6) {
            SecureField(label, text: key)
                .textFieldStyle(.roundedBorder)
                .onChange(of: key.wrappedValue) { _ in onClear() }
            apiKeyBadge(testState)
            Button("Test") { onTest() }
                .disabled(key.wrappedValue.isEmpty || testState == .testing)
        }
    }

    @ViewBuilder
    private func apiKeyBadge(_ state: APIKeyTestState) -> some View {
        switch state {
        case .idle:
            EmptyView()
        case .testing:
            ProgressView().scaleEffect(0.7).frame(width: 18, height: 18)
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .frame(width: 18, height: 18)
        case .invalid(let msg):
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .frame(width: 18, height: 18)
                .help(msg)
        }
    }

    private func voiceLabel(_ voice: AVSpeechSynthesisVoice) -> String {
        switch voice.quality {
        case .premium:  return "\(voice.name) ★★"
        case .enhanced: return "\(voice.name) ★"
        default:        return voice.name
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
}

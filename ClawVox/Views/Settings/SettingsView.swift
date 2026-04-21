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
                    SecureField("OpenAI API Key", text: $settingsVM.settings.openAIAPIKey)
                        .textFieldStyle(.roundedBorder)
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
                        SecureField("OpenAI API Key", text: $settingsVM.settings.openAIAPIKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    Picker("Voice", selection: $settingsVM.settings.openAITTSVoice) {
                        ForEach(AppSettings.openAIVoices, id: \.self) { voice in
                            Text(voice.capitalized).tag(voice)
                        }
                    }
                }
                if settingsVM.settings.ttsProvider == .elevenlabs {
                    SecureField("ElevenLabs API Key", text: $settingsVM.settings.elevenlabsAPIKey)
                        .textFieldStyle(.roundedBorder)
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

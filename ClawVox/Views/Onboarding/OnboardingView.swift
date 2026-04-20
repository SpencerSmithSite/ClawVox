import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @State private var step = 0
    @State private var connectionStatus: ConnectionStatus = .idle

    private let totalSteps = 4

    enum ConnectionStatus: Equatable {
        case idle, testing, success
        case failure(String)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                stepDots
                    .padding(.top, 40)
                Spacer()
                contentForStep
                    .padding(.horizontal, 60)
                    .animation(.none, value: step)
                Spacer()
                navRow
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var contentForStep: some View {
        switch step {
        case 0: welcomeStep
        case 1: connectStep
        case 2: voiceStep
        default: doneStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color(hex: "#00CFFF"))
            Text("Welcome to ClawVox")
                .font(.largeTitle).fontWeight(.bold)
                .foregroundStyle(.white)
            Text("Your AI voice companion for OpenClaw.\nLet's get you configured in a few quick steps.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var connectStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Connect to OpenClaw")
                    .font(.title2).fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text("Enter the URL where your OpenClaw gateway is running.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("GATEWAY URL").font(.caption).foregroundStyle(.secondary)
                TextField("http://localhost:18789", text: $settingsVM.settings.gatewayURL)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .onChange(of: settingsVM.settings.gatewayURL) { _ in
                        connectionStatus = .idle
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("AUTH TOKEN (optional)").font(.caption).foregroundStyle(.secondary)
                SecureField("Leave blank if not required", text: $settingsVM.settings.authToken)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: settingsVM.settings.authToken) { _ in
                        connectionStatus = .idle
                    }
            }

            HStack(spacing: 12) {
                Button("Test Connection", action: testConnection)
                    .disabled(connectionStatus == .testing
                              || settingsVM.settings.gatewayURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if connectionStatus == .testing {
                    ProgressView().controlSize(.small)
                } else if case .success = connectionStatus {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                } else if case .failure(let msg) = connectionStatus {
                    Label(msg, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var voiceStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Voice Settings")
                    .font(.title2).fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text("Choose how ClawVox listens and speaks. You can change these later in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Picker("Speech-to-Text", selection: $settingsVM.settings.sttProvider) {
                ForEach(AppSettings.STTProvider.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }

            Picker("Text-to-Speech", selection: $settingsVM.settings.ttsProvider) {
                ForEach(AppSettings.TTSProvider.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }

            if settingsVM.settings.sttProvider == .whisper
                || settingsVM.settings.ttsProvider == .openai {
                VStack(alignment: .leading, spacing: 6) {
                    Text("OPENAI API KEY").font(.caption).foregroundStyle(.secondary)
                    SecureField("sk-…", text: $settingsVM.settings.openAIAPIKey)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var doneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            Text("You're all set!")
                .font(.largeTitle).fontWeight(.bold)
                .foregroundStyle(.white)
            Text("ClawVox is configured and ready.\nOpen the chat to start talking with your agent.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Navigation

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Circle()
                    .fill(i == step ? Color(hex: "#00CFFF") : Color.white.opacity(0.2))
                    .frame(width: 7, height: 7)
                    .animation(.easeInOut(duration: 0.2), value: step)
            }
        }
    }

    private var navRow: some View {
        HStack {
            if step > 0 && step < totalSteps - 1 {
                Button("Back") { step -= 1 }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if step < totalSteps - 2 {
                Button("Next") { step += 1 }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            } else if step == totalSteps - 2 {
                Button("Finish Setup") { step += 1 }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Launch ClawVox") {
                    settingsVM.completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    // MARK: - Connection test

    private func testConnection() {
        connectionStatus = .testing
        let url = settingsVM.settings.gatewayURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = settingsVM.settings.authToken
        Task {
            guard let healthURL = URL(string: url + "/health") else {
                connectionStatus = .failure("Invalid URL")
                return
            }
            var req = URLRequest(url: healthURL)
            req.timeoutInterval = 5
            if !token.isEmpty {
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            do {
                let (_, response) = try await URLSession.shared.data(for: req)
                guard let http = response as? HTTPURLResponse else {
                    connectionStatus = .failure("No response")
                    return
                }
                if (200...299).contains(http.statusCode) {
                    connectionStatus = .success
                } else if http.statusCode == 401 || http.statusCode == 403 {
                    connectionStatus = .failure("Auth failed (\(http.statusCode))")
                } else {
                    connectionStatus = .failure("HTTP \(http.statusCode)")
                }
            } catch {
                connectionStatus = .failure("Cannot reach server")
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(SettingsViewModel())
        .frame(width: 800, height: 600)
}

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject private var settingsVM: SettingsViewModel
    @EnvironmentObject private var conversationVM: ConversationViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider().overlay(Color(hex: "#222222"))
            messageList
            Divider().overlay(Color(hex: "#222222"))
            inputBar
        }
        .background(Color.black)
        .onAppear {
            conversationVM.update(settings: settingsVM.settings)
        }
        .onChange(of: settingsVM.settings) { newSettings in
            conversationVM.update(settings: newSettings)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            OrbView(level: Double(conversationVM.audioLevel))
                .frame(width: 28, height: 28)
            Text("ClawVox")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            connectionBadge
            Button(action: { conversationVM.isTTSEnabled.toggle() }) {
                Image(systemName: conversationVM.isTTSEnabled ? "speaker.wave.2.fill" : "speaker.slash")
                    .foregroundStyle(conversationVM.isTTSEnabled ? Color(hex: "#00CFFF") : .secondary)
            }
            .buttonStyle(.plain)
            .help(conversationVM.isTTSEnabled ? "Mute responses" : "Unmute responses")
            Button {
                conversationVM.clearConversation()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Clear conversation")
            .opacity(conversationVM.messages.isEmpty ? 0 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#0D0D0D"))
    }

    private var connectionBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(connectionColor)
                .frame(width: 7, height: 7)
            Text(connectionLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
        case .connected:           return "Connected"
        case .connecting:          return "Connecting…"
        case .disconnected:        return "Disconnected"
        case .error(let msg):      return msg
        }
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if conversationVM.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(conversationVM.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(16)
            }
            .onChange(of: conversationVM.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: conversationVM.messages.last?.content) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
        .background(Color.black)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = conversationVM.messages.last else { return }
        withAnimation(.easeOut(duration: 0.15)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            OrbView(level: Double(conversationVM.audioLevel))
                .frame(width: 80, height: 80)
            Text("Ask me anything")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            Text("Your OpenClaw agent is ready")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Button(action: { conversationVM.toggleMic() }) {
                Image(systemName: conversationVM.isListening ? "mic.fill" : "mic")
                    .font(.title2)
                    .foregroundStyle(conversationVM.isListening ? .red : .secondary)
            }
            .buttonStyle(.plain)
            .help(conversationVM.isListening ? "Stop listening" : "Start voice input")

            TextField("Message…", text: $conversationVM.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(.white)
                .lineLimit(1...6)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#1A1A1A"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onSubmit {
                    conversationVM.sendMessage()
                }

            if conversationVM.isLoading {
                Button(action: { conversationVM.cancelStream() }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Cancel")
            } else {
                let canSend = !conversationVM.inputText.isBlank
                Button(action: { conversationVM.sendMessage() }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? Color(hex: "#00CFFF") : .gray)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .help("Send")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "#0D0D0D"))
    }
}

#Preview {
    MainWindowView()
        .environmentObject(SettingsViewModel())
        .environmentObject(ConversationViewModel())
        .frame(width: 800, height: 600)
}

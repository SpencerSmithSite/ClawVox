import SwiftUI

struct ChatBubbleView: View {
    let message: Message
    /// When true, a blinking block cursor is appended to indicate live streaming.
    var isStreaming: Bool = false

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isUser { Spacer(minLength: 60) }

            if isStreaming {
                streamingBubble
            } else {
                staticBubble(text: message.content.isEmpty ? "…" : message.content)
            }

            if !isUser { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    // MARK: - Bubble variants

    private var streamingBubble: some View {
        // 0.6 s period cursor blink — fires at 1.67 Hz, well within SwiftUI's update budget.
        TimelineView(.periodic(from: .now, by: 0.6)) { timeline in
            let cursorOn = Int(timeline.date.timeIntervalSinceReferenceDate / 0.6) % 2 == 0
            let display = message.content + (cursorOn ? "▊" : "")
            staticBubble(text: display.isEmpty ? "▊" : display)
        }
    }

    @ViewBuilder
    private func staticBubble(text: String) -> some View {
        if isUser {
            Text(text)
                .font(.body)
                .foregroundStyle(Color.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#00CFFF"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(hex: "#00CFFF").opacity(0.35), radius: 12, x: 0, y: 4)
                .textSelection(.enabled)
        } else {
            Text(text)
                .font(.body)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: 16)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ChatBubbleView(message: Message(role: .user, content: "Hello, what can you do?"))
        ChatBubbleView(message: Message(role: .assistant, content: "I can help you with many tasks — ask me anything!"))
        ChatBubbleView(message: Message(role: .assistant, content: "Streaming response in progress"), isStreaming: true)
        ChatBubbleView(message: Message(role: .assistant, content: ""), isStreaming: true)
    }
    .padding()
    .background(Color.black)
    .frame(width: 500)
}

import SwiftUI

struct ChatBubbleView: View {
    let message: Message

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isUser { Spacer(minLength: 60) }

            Text(message.content.isEmpty ? "…" : message.content)
                .font(.body)
                .foregroundStyle(isUser ? Color.black : Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isUser ? Color(hex: "#00CFFF") : Color(hex: "#1E1E1E"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .textSelection(.enabled)

            if !isUser { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}

#Preview {
    VStack(spacing: 8) {
        ChatBubbleView(message: Message(role: .user, content: "Hello, what can you do?"))
        ChatBubbleView(message: Message(role: .assistant, content: "I can help you with many tasks — ask me anything!"))
        ChatBubbleView(message: Message(role: .assistant, content: ""))
    }
    .padding()
    .background(Color.black)
    .frame(width: 500)
}

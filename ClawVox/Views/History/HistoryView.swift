import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var conversationVM: ConversationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showClearAllAlert = false

    private var filtered: [Conversation] {
        guard !searchText.isBlank else { return conversationVM.savedConversations }
        let q = searchText.lowercased()
        return conversationVM.savedConversations.filter {
            $0.title.lowercased().contains(q)
                || $0.messages.contains { $0.content.lowercased().contains(q) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            searchBar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            Divider().opacity(0.3)
            conversationList
        }
        .background(Color.black)
        .frame(width: 460, height: 540)
        .alert("Clear All History?", isPresented: $showClearAllAlert) {
            Button("Clear All", role: .destructive) { conversationVM.deleteAllConversations() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all saved conversations.")
        }
    }

    // MARK: - Subviews

    private var toolbar: some View {
        HStack {
            Text("Conversation History")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Button("Clear All") { showClearAllAlert = true }
                .foregroundStyle(.red)
                .buttonStyle(.plain)
                .disabled(conversationVM.savedConversations.isEmpty)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Color.white.opacity(0.06).frame(height: 0.5)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            TextField("Search conversations…", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassCard(cornerRadius: 8)
    }

    @ViewBuilder
    private var conversationList: some View {
        if filtered.isEmpty {
            Spacer()
            Text(conversationVM.savedConversations.isEmpty ? "No conversations yet" : "No results")
                .foregroundStyle(.secondary)
            Spacer()
        } else {
            List {
                ForEach(filtered) { conversation in
                    Button {
                        conversationVM.loadConversation(conversation)
                        dismiss()
                    } label: {
                        ConversationRowView(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            conversationVM.deleteConversation(conversation)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

private struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(1)
            HStack(spacing: 4) {
                Text(conversation.startedAt, style: .date)
                Text("·")
                Text("\(conversation.messages.filter { $0.role != .system }.count) messages")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HistoryView()
        .environmentObject(ConversationViewModel())
}

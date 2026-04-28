import SwiftUI

struct ConversationsView: View {
    @Environment(AuthService.self) private var auth
    @Environment(MessageService.self) private var messageService
    @Environment(StatusEngine.self) private var statusEngine

    var body: some View {
        Group {
            if messageService.conversations.isEmpty && !messageService.isLoading {
                ContentUnavailableView(
                    "No Messages Yet",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Give status to someone or earn status to start messaging.")
                )
            } else {
                List(messageService.conversations) { conversation in
                    NavigationLink(value: conversation) {
                        ConversationRow(
                            conversation: conversation,
                            currentUserId: auth.currentUser?.id ?? ""
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Messages")
        .navigationDestination(for: Conversation.self) { conversation in
            ChatView(conversation: conversation)
        }
        .task {
            if let user = auth.currentUser {
                await messageService.loadConversations(for: user.id)
            }
        }
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String

    private var otherUserId: String {
        conversation.participantIds.first { $0 != currentUserId } ?? ""
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(.quaternary)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(otherUserId.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherUserId)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if let date = conversation.lastMessageAt {
                        Text(shortTime(date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text(conversation.lastMessage ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue, in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func shortTime(_ date: Date) -> String {
        let seconds = Date.now.timeIntervalSince(date)
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h" }
        return "\(Int(seconds / 86400))d"
    }
}

#Preview {
    NavigationStack {
        ConversationsView()
    }
    .environment(AuthService.preview)
    .environment(MessageService.preview)
    .environment(StatusEngine.preview)
}

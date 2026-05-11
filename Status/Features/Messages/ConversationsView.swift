import SwiftUI
@preconcurrency import FirebaseFirestore

struct ConversationsView: View {
    @Environment(AuthService.self) private var auth
    @Environment(MessageService.self) private var messageService
    @Environment(StatusEngine.self) private var statusEngine
    @State private var userNames: [String: String] = [:]

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
                    let name = otherUserName(for: conversation)
                    if userNames[conversation.participantIds.first { $0 != auth.currentUser?.id } ?? ""] != nil {
                        NavigationLink(value: conversation) {
                            ConversationRow(
                                conversation: conversation,
                                currentUserId: auth.currentUser?.id ?? "",
                                otherUserName: name
                            )
                        }
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
                messageService.startListeningToConversations(for: user.id)
            }
        }
        .onChange(of: messageService.conversations) {
            Task { await fetchUserNames() }
        }
    }

    private func otherUserName(for conversation: Conversation) -> String {
        let otherId = conversation.participantIds.first { $0 != auth.currentUser?.id } ?? ""
        return userNames[otherId] ?? otherId
    }

    private func fetchUserNames() async {
        let currentId = auth.currentUser?.id ?? ""
        let db = Firestore.firestore()
        for conversation in messageService.conversations {
            for participantId in conversation.participantIds where participantId != currentId {
                if userNames[participantId] == nil {
                    if let doc = try? await db.collection("users").document(participantId).getDocument(),
                       let user = try? doc.data(as: User.self) {
                        userNames[participantId] = user.displayName
                    }
                }
            }
        }
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String
    let otherUserName: String

    private var otherUserId: String {
        conversation.participantIds.first { $0 != currentUserId } ?? ""
    }

    // Encrypted messages have base64 ciphertext — detect and hide
    private var lastMessagePreview: String {
        guard let msg = conversation.lastMessage, !msg.isEmpty else {
            return ""
        }
        // If it looks like base64 ciphertext (no spaces, long), hide it
        if msg.count > 30 && !msg.contains(" ") {
            return ""
        }
        return msg
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarPlaceholder(name: otherUserName, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherUserName)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if let date = conversation.lastMessageAt {
                        Text(shortTime(date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text(lastMessagePreview)
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

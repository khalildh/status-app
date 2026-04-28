import Foundation

@Observable
final class MessageService {
    var conversations: [Conversation] = []
    var messagesByConversation: [String: [Message]] = [:]
    var isLoading = false

    func loadConversations(for userId: String) async {
        isLoading = true
        // In production: Firestore real-time listener via AsyncThrowingStream
        // For now: mock data
        try? await Task.sleep(for: .milliseconds(300))
        conversations = Conversation.mocks.filter { $0.participantIds.contains(userId) }
        isLoading = false
    }

    func loadMessages(for conversationId: String) async {
        // In production: paginated Firestore query with real-time updates
        try? await Task.sleep(for: .milliseconds(200))
        if messagesByConversation[conversationId] == nil {
            messagesByConversation[conversationId] = Message.mocks(
                conversationId: conversationId,
                between: "user_1",
                userB: "user_2"
            )
        }
    }

    func sendMessage(conversationId: String, senderId: String, text: String) async {
        let message = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: senderId,
            text: text,
            sentAt: .now
        )

        messagesByConversation[conversationId, default: []].append(message)

        // Update conversation's last message
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[idx].lastMessage = text
            conversations[idx].lastMessageAt = .now
            conversations[idx].lastSenderId = senderId
        }
    }

    func startConversation(between userA: String, and userB: String) -> Conversation {
        // Check if conversation already exists
        if let existing = conversations.first(where: {
            $0.participantIds.contains(userA) && $0.participantIds.contains(userB)
        }) {
            return existing
        }

        let conversation = Conversation(
            id: UUID().uuidString,
            participantIds: [userA, userB],
            unreadCount: 0,
            createdAt: .now
        )
        conversations.append(conversation)
        return conversation
    }

    static var preview: MessageService {
        let service = MessageService()
        service.conversations = Conversation.mocks
        service.messagesByConversation["conv_1"] = Message.mocks(
            conversationId: "conv_1", between: "user_1", userB: "user_2"
        )
        return service
    }
}

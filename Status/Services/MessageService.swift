import Foundation
@preconcurrency import FirebaseFirestore

@MainActor
@Observable
final class MessageService {
    var conversations: [Conversation] = []
    var messagesByConversation: [String: [Message]] = [:]
    var isLoading = false

    @ObservationIgnored private var _db: Firestore? = nil
    private var db: Firestore { if _db == nil { _db = Firestore.firestore() }; return _db! }
    @ObservationIgnored private var conversationsListener: ListenerRegistration?
    @ObservationIgnored private var messageListeners: [String: ListenerRegistration] = [:]

    deinit {
        conversationsListener?.remove()
        messageListeners.values.forEach { $0.remove() }
    }

    // MARK: - Conversations

    func startListeningToConversations(for userId: String) {
        conversationsListener?.remove()

        conversationsListener = db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                guard let docs = snapshot?.documents else { return }
                self.conversations = docs.compactMap { try? $0.data(as: Conversation.self) }
            }
    }

    func stopListeningToConversations() {
        conversationsListener?.remove()
        conversationsListener = nil
    }

    // MARK: - Messages

    func startListeningToMessages(for conversationId: String) {
        messageListeners[conversationId]?.remove()

        messageListeners[conversationId] = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "sentAt", descending: false)
            .limit(toLast: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                guard let docs = snapshot?.documents else { return }
                self.messagesByConversation[conversationId] = docs.compactMap {
                    try? $0.data(as: Message.self)
                }
            }
    }

    func stopListeningToMessages(for conversationId: String) {
        messageListeners[conversationId]?.remove()
        messageListeners.removeValue(forKey: conversationId)
    }

    // MARK: - Send Message

    func sendMessage(conversationId: String, senderId: String, text: String, ephemeralPublicKey: String? = nil) async throws {
        let message = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: senderId,
            text: text,
            ephemeralPublicKey: ephemeralPublicKey,
            sentAt: .now
        )

        let batch = db.batch()

        // Write message
        let msgRef = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(message.id)
        try batch.setData(from: message, forDocument: msgRef)

        // Update conversation metadata
        let convRef = db.collection("conversations").document(conversationId)
        batch.updateData([
            "lastMessage": text,
            "lastMessageAt": Timestamp(date: .now),
            "lastSenderId": senderId,
        ], forDocument: convRef)

        try await batch.commit()
    }

    // MARK: - Start Conversation

    func startConversation(between userA: String, and userB: String) async throws -> Conversation {
        // Check if conversation already exists
        if let existing = conversations.first(where: {
            $0.participantIds.contains(userA) && $0.participantIds.contains(userB)
        }) {
            return existing
        }

        let conversation = Conversation(
            id: UUID().uuidString,
            participantIds: [userA, userB],
            lastMessage: "Status sent!",
            lastMessageAt: .now,
            lastSenderId: userA,
            unreadCount: 0,
            createdAt: .now
        )

        try db.collection("conversations").document(conversation.id).setData(from: conversation)
        return conversation
    }

    // MARK: - Preview

    static var preview: MessageService {
        let service = MessageService()
        service.conversations = Conversation.mocks
        service.messagesByConversation["conv_1"] = Message.mocks(
            conversationId: "conv_1", between: "user_1", userB: "user_2"
        )
        return service
    }
}

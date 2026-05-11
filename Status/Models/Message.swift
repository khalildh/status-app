import Foundation

struct Message: Identifiable, Codable, Hashable {
    var id: String
    var conversationId: String
    var senderId: String
    var text: String                    // Ciphertext for recipient
    var ephemeralPublicKey: String?     // Ephemeral key for recipient to decrypt
    var sentAt: Date
    var readAt: Date?
    var senderCiphertext: String?       // Ciphertext for sender to decrypt their own message
    var senderEphemeralPublicKey: String? // Ephemeral key for sender to decrypt

    var isRead: Bool { readAt != nil }
    var isEncrypted: Bool { ephemeralPublicKey != nil }
}

extension Message {
    static func mocks(conversationId: String, between userA: String, userB: String) -> [Message] {
        [
            Message(id: "msg_1", conversationId: conversationId, senderId: userB, text: "Hey, saw you on the leaderboard", sentAt: .now.addingTimeInterval(-7200), readAt: .now.addingTimeInterval(-7100)),
            Message(id: "msg_2", conversationId: conversationId, senderId: userA, text: "Yeah! Been grinding this week", sentAt: .now.addingTimeInterval(-7000), readAt: .now.addingTimeInterval(-6900)),
            Message(id: "msg_3", conversationId: conversationId, senderId: userB, text: "I sent you some status", sentAt: .now.addingTimeInterval(-6800), readAt: .now.addingTimeInterval(-6700)),
            Message(id: "msg_4", conversationId: conversationId, senderId: userA, text: "Appreciate that! Sent some back", sentAt: .now.addingTimeInterval(-3600), readAt: nil),
            Message(id: "msg_5", conversationId: conversationId, senderId: userB, text: "That broadcast was fire", sentAt: .now.addingTimeInterval(-300), readAt: nil),
        ]
    }
}

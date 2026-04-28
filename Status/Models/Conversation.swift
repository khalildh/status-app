import Foundation

struct Conversation: Identifiable, Codable, Hashable {
    var id: String
    var participantIds: [String]
    var lastMessage: String?
    var lastMessageAt: Date?
    var lastSenderId: String?
    var unreadCount: Int
    var createdAt: Date
}

extension Conversation {
    static let mocks: [Conversation] = [
        Conversation(
            id: "conv_1",
            participantIds: ["user_1", "user_2"],
            lastMessage: "That broadcast was fire",
            lastMessageAt: .now.addingTimeInterval(-300),
            lastSenderId: "user_2",
            unreadCount: 1,
            createdAt: .now.addingTimeInterval(-86400 * 5)
        ),
        Conversation(
            id: "conv_2",
            participantIds: ["user_1", "user_4"],
            lastMessage: "Thanks for the status!",
            lastMessageAt: .now.addingTimeInterval(-3600),
            lastSenderId: "user_1",
            unreadCount: 0,
            createdAt: .now.addingTimeInterval(-86400 * 3)
        ),
        Conversation(
            id: "conv_3",
            participantIds: ["user_1", "user_5"],
            lastMessage: "Let's connect",
            lastMessageAt: .now.addingTimeInterval(-86400),
            lastSenderId: "user_5",
            unreadCount: 3,
            createdAt: .now.addingTimeInterval(-86400 * 2)
        ),
    ]
}

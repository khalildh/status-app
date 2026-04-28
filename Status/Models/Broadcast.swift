import Foundation

struct Broadcast: Identifiable, Codable {
    var id: String
    var authorId: String
    var text: String
    var createdAt: Date
    var expiresAt: Date           // 24h after creation
    var reachCount: Int           // How many people received it
    var statusReactions: Int      // People who gave status in response

    var isExpired: Bool {
        Date.now > expiresAt
    }

    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSince(.now))
    }

    static let lifetimeSeconds: TimeInterval = 24 * 3600
}

extension Broadcast {
    static let mocks: [Broadcast] = [
        Broadcast(
            id: "bc_1",
            authorId: "user_4",
            text: "Just shipped something big. If you know, you know.",
            createdAt: .now.addingTimeInterval(-3600),
            expiresAt: .now.addingTimeInterval(20 * 3600),
            reachCount: 847,
            statusReactions: 23
        ),
        Broadcast(
            id: "bc_2",
            authorId: "user_2",
            text: "Looking for a collaborator on a new project. DM me if you've got status.",
            createdAt: .now.addingTimeInterval(-7200),
            expiresAt: .now.addingTimeInterval(16 * 3600),
            reachCount: 312,
            statusReactions: 8
        ),
        Broadcast(
            id: "bc_3",
            authorId: "user_5",
            text: "Hot take: the leaderboard matters less than who you've given status to.",
            createdAt: .now.addingTimeInterval(-14400),
            expiresAt: .now.addingTimeInterval(9 * 3600),
            reachCount: 156,
            statusReactions: 41
        ),
    ]
}

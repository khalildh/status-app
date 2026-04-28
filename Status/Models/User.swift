import Foundation

struct User: Identifiable, Codable, Hashable {
    var id: String
    var username: String
    var displayName: String
    var avatarURL: String?
    var bio: String?
    var joinedAt: Date

    // Status economy
    var statusBalance: Int          // Points available to give
    var weeklyRefillAmount: Int     // How many free points per week (default 5)
    var lastRefillDate: Date
    var totalStatusReceived: Double // Weighted incoming status (for leaderboard)
    var leaderboardRank: Int?

    // Limits
    var broadcastsToday: Int
    var lastBroadcastDate: Date?

    static let weeklyFreePoints = 5
    static let maxPurchasePerWeek = 50
}

extension User {
    static let mock = User(
        id: "user_1",
        username: "khalid",
        displayName: "Khalid",
        avatarURL: nil,
        bio: "Building things",
        joinedAt: .now.addingTimeInterval(-86400 * 30),
        statusBalance: 5,
        weeklyRefillAmount: 5,
        lastRefillDate: .now,
        totalStatusReceived: 142.5,
        leaderboardRank: 12,
        broadcastsToday: 0,
        lastBroadcastDate: nil
    )

    static let mockOthers: [User] = [
        User(id: "user_2", username: "maya", displayName: "Maya Chen", avatarURL: nil, bio: "Designer", joinedAt: .now.addingTimeInterval(-86400 * 60), statusBalance: 3, weeklyRefillAmount: 5, lastRefillDate: .now, totalStatusReceived: 890.2, leaderboardRank: 3, broadcastsToday: 1, lastBroadcastDate: .now),
        User(id: "user_3", username: "alex", displayName: "Alex Rivera", avatarURL: nil, bio: "Music producer", joinedAt: .now.addingTimeInterval(-86400 * 45), statusBalance: 8, weeklyRefillAmount: 5, lastRefillDate: .now, totalStatusReceived: 45.0, leaderboardRank: 87, broadcastsToday: 0, lastBroadcastDate: nil),
        User(id: "user_4", username: "jordan", displayName: "Jordan Lee", avatarURL: nil, bio: nil, joinedAt: .now.addingTimeInterval(-86400 * 20), statusBalance: 2, weeklyRefillAmount: 5, lastRefillDate: .now, totalStatusReceived: 1250.8, leaderboardRank: 1, broadcastsToday: 1, lastBroadcastDate: .now),
        User(id: "user_5", username: "sam", displayName: "Sam Park", avatarURL: nil, bio: "Photographer", joinedAt: .now.addingTimeInterval(-86400 * 15), statusBalance: 4, weeklyRefillAmount: 5, lastRefillDate: .now, totalStatusReceived: 320.0, leaderboardRank: 8, broadcastsToday: 0, lastBroadcastDate: nil),
    ]
}

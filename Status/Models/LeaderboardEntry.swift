import Foundation

struct LeaderboardEntry: Identifiable, Hashable {
    var id: String { userId }
    var userId: String
    var username: String
    var displayName: String
    var avatarURL: String?
    var rank: Int
    var weightedScore: Double     // Incoming status weighted by giver's status
    var changeFromLastWeek: Int   // +3 means moved up 3 spots

    var isRising: Bool { changeFromLastWeek > 0 }
    var isFalling: Bool { changeFromLastWeek < 0 }
}

enum LeaderboardScope: String, CaseIterable {
    case weekly = "This Week"
    case monthly = "This Month"
    case allTime = "All Time"
}

extension LeaderboardEntry {
    static let mocks: [LeaderboardEntry] = [
        LeaderboardEntry(userId: "user_4", username: "jordan", displayName: "Jordan Lee", rank: 1, weightedScore: 1250.8, changeFromLastWeek: 0),
        LeaderboardEntry(userId: "user_6", username: "nina", displayName: "Nina Patel", rank: 2, weightedScore: 1100.2, changeFromLastWeek: 2),
        LeaderboardEntry(userId: "user_2", username: "maya", displayName: "Maya Chen", rank: 3, weightedScore: 890.2, changeFromLastWeek: -1),
        LeaderboardEntry(userId: "user_7", username: "marcus", displayName: "Marcus Johnson", rank: 4, weightedScore: 780.5, changeFromLastWeek: 1),
        LeaderboardEntry(userId: "user_8", username: "elena", displayName: "Elena Volkov", rank: 5, weightedScore: 650.0, changeFromLastWeek: -2),
        LeaderboardEntry(userId: "user_5", username: "sam", displayName: "Sam Park", rank: 6, weightedScore: 320.0, changeFromLastWeek: 3),
        LeaderboardEntry(userId: "user_9", username: "kai", displayName: "Kai Tanaka", rank: 7, weightedScore: 290.4, changeFromLastWeek: 0),
        LeaderboardEntry(userId: "user_10", username: "priya", displayName: "Priya Sharma", rank: 8, weightedScore: 245.1, changeFromLastWeek: -1),
        LeaderboardEntry(userId: "user_1", username: "khalid", displayName: "Khalid", rank: 12, weightedScore: 142.5, changeFromLastWeek: 4),
    ]
}

import Foundation

struct StatusTransaction: Identifiable, Codable {
    var id: String
    var fromUserId: String
    var toUserId: String
    var amount: Int
    var createdAt: Date
    var expiresAt: Date          // For decay — 90 day window
    var weightedValue: Double    // amount * giver's status weight

    var isExpired: Bool {
        Date.now > expiresAt
    }

    static let decayWindowDays: TimeInterval = 90 * 86400
}

extension StatusTransaction {
    static func mock(from: String, to: String, amount: Int = 1, daysAgo: Int = 0) -> StatusTransaction {
        let created = Date.now.addingTimeInterval(-Double(daysAgo) * 86400)
        return StatusTransaction(
            id: UUID().uuidString,
            fromUserId: from,
            toUserId: to,
            amount: amount,
            createdAt: created,
            expiresAt: created.addingTimeInterval(decayWindowDays),
            weightedValue: Double(amount) * 1.0
        )
    }
}

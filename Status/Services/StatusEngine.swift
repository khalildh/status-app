import Foundation

@Observable
final class StatusEngine {
    var transactions: [StatusTransaction] = []
    var isLoading = false
    var error: String?

    // MARK: - Core Rules

    /// Can `fromUser` message `toUser`?
    /// Rules:
    /// 1. You can message anyone with less status than you
    /// 2. You can message someone if you gave status to someone who gave status to them (transitive)
    func canMessage(from fromUser: User, to toUser: User) -> Bool {
        // Rule 1: Higher status can message down
        if fromUser.totalStatusReceived > toUser.totalStatusReceived {
            return true
        }

        // Rule 2: Transitive — check if there's a path through status-giving
        return hasTransitivePath(from: fromUser.id, to: toUser.id)
    }

    /// Check for transitive messaging path:
    /// fromUser gave status to intermediary, and intermediary gave status to toUser
    private func hasTransitivePath(from fromId: String, to toId: String) -> Bool {
        let activeTransactions = transactions.filter { !$0.isExpired }

        // Direct: fromUser gave status to toUser
        if activeTransactions.contains(where: { $0.fromUserId == fromId && $0.toUserId == toId }) {
            return true
        }

        // Transitive: fromUser gave status to X, and X gave status to toUser
        let peopleFromUserGaveStatusTo = Set(
            activeTransactions
                .filter { $0.fromUserId == fromId }
                .map { $0.toUserId }
        )

        for intermediary in peopleFromUserGaveStatusTo {
            if activeTransactions.contains(where: { $0.fromUserId == intermediary && $0.toUserId == toId }) {
                return true
            }
        }

        return false
    }

    // MARK: - Giving Status

    func giveStatus(from fromUser: inout User, to toUserId: String, amount: Int) -> StatusTransaction? {
        guard amount > 0, fromUser.statusBalance >= amount else {
            error = fromUser.statusBalance == 0
                ? "No status points left. Refills weekly or buy more."
                : "Not enough status points."
            return nil
        }

        fromUser.statusBalance -= amount

        let transaction = StatusTransaction(
            id: UUID().uuidString,
            fromUserId: fromUser.id,
            toUserId: toUserId,
            amount: amount,
            createdAt: .now,
            expiresAt: .now.addingTimeInterval(StatusTransaction.decayWindowDays),
            weightedValue: Double(amount) * statusWeight(for: fromUser)
        )

        transactions.append(transaction)
        return transaction
    }

    /// Weight of a status gift is based on the giver's own incoming status.
    /// Higher-status givers make their gifts count more on the leaderboard.
    func statusWeight(for user: User) -> Double {
        let base = max(1.0, user.totalStatusReceived)
        return log2(base + 1) // Logarithmic scaling to prevent runaway whale effects
    }

    // MARK: - Weekly Refill

    func refillIfNeeded(user: inout User) {
        let calendar = Calendar.current
        let lastRefill = calendar.startOfDay(for: user.lastRefillDate)
        let today = calendar.startOfDay(for: .now)

        guard let daysSince = calendar.dateComponents([.day], from: lastRefill, to: today).day,
              daysSince >= 7 else { return }

        user.statusBalance += user.weeklyRefillAmount
        user.lastRefillDate = today
    }

    // MARK: - Leaderboard

    func computeLeaderboard() -> [LeaderboardEntry] {
        let active = transactions.filter { !$0.isExpired }

        // Group by recipient, sum weighted values
        var scores: [String: Double] = [:]
        for tx in active {
            scores[tx.toUserId, default: 0] += tx.weightedValue
        }

        return scores
            .sorted { $0.value > $1.value }
            .enumerated()
            .map { index, entry in
                LeaderboardEntry(
                    userId: entry.key,
                    username: entry.key,
                    displayName: entry.key,
                    rank: index + 1,
                    weightedScore: entry.value,
                    changeFromLastWeek: 0
                )
            }
    }

    // MARK: - Broadcast Eligibility

    /// Users who gave you status receive your broadcasts
    func broadcastAudience(for userId: String) -> [String] {
        let active = transactions.filter { !$0.isExpired }
        // People who gave status TO this user — they opted in by elevating
        let directAudience = Set(active.filter { $0.toUserId == userId }.map { $0.fromUserId })

        // Transitive: people who gave status to someone in the direct audience
        var fullAudience = directAudience
        for member in directAudience {
            let transitive = active.filter { $0.toUserId == member }.map { $0.fromUserId }
            fullAudience.formUnion(transitive)
        }

        fullAudience.remove(userId) // Don't broadcast to yourself
        return Array(fullAudience)
    }

    func canBroadcast(user: User) -> Bool {
        guard let lastBroadcast = user.lastBroadcastDate else { return true }
        return !Calendar.current.isDate(lastBroadcast, inSameDayAs: .now)
    }

    // MARK: - Preview helper

    static var preview: StatusEngine {
        let engine = StatusEngine()
        engine.transactions = [
            .mock(from: "user_1", to: "user_2", amount: 2),
            .mock(from: "user_1", to: "user_4", amount: 1),
            .mock(from: "user_2", to: "user_4", amount: 3),
            .mock(from: "user_3", to: "user_1", amount: 1),
            .mock(from: "user_4", to: "user_1", amount: 2, daysAgo: 5),
            .mock(from: "user_5", to: "user_1", amount: 1, daysAgo: 2),
            .mock(from: "user_2", to: "user_1", amount: 2, daysAgo: 10),
        ]
        return engine
    }
}

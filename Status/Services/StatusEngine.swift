import Foundation
@preconcurrency import FirebaseFirestore

@MainActor
@Observable
final class StatusEngine {
    var transactions: [StatusTransaction] = []
    var isLoading = false
    var error: String?

    @ObservationIgnored private var _db: Firestore? = nil
    private var db: Firestore { if _db == nil { _db = Firestore.firestore() }; return _db! }
    nonisolated(unsafe) private var listener: ListenerRegistration?

    nonisolated deinit {
        listener?.remove()
    }

    // MARK: - Real-time Listener

    /// Start listening to all active (non-expired) transactions relevant to this user.
    func startListening(for userId: String) {
        listener?.remove()

        let cutoff = Date.now.addingTimeInterval(-StatusTransaction.decayWindowDays)

        listener = db.collection("statusTransactions")
            .whereField("createdAt", isGreaterThan: Timestamp(date: cutoff))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    self.error = error.localizedDescription
                    return
                }
                guard let docs = snapshot?.documents else { return }
                self.transactions = docs.compactMap { try? $0.data(as: StatusTransaction.self) }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Core Rules

    /// Can `fromUser` message `toUser`?
    /// Block check is done externally via BlockService — this only checks status rules.
    func canMessage(from fromUser: User, to toUser: User, blockedIds: Set<String> = []) -> Bool {
        // Blocked users can never message each other
        if blockedIds.contains(fromUser.id) || blockedIds.contains(toUser.id) {
            return false
        }
        if fromUser.totalStatusReceived > toUser.totalStatusReceived {
            return true
        }
        return hasTransitivePath(from: fromUser.id, to: toUser.id)
    }

    private func hasTransitivePath(from fromId: String, to toId: String) -> Bool {
        let active = transactions.filter { !$0.isExpired }

        if active.contains(where: { $0.fromUserId == fromId && $0.toUserId == toId }) {
            return true
        }

        let peopleFromUserGaveStatusTo = Set(
            active.filter { $0.fromUserId == fromId }.map { $0.toUserId }
        )

        for intermediary in peopleFromUserGaveStatusTo {
            if active.contains(where: { $0.fromUserId == intermediary && $0.toUserId == toId }) {
                return true
            }
        }

        return false
    }

    // MARK: - Giving Status

    func giveStatus(from fromUser: User, to toUserId: String, amount: Int) async throws {
        guard amount > 0, fromUser.statusBalance >= amount else {
            error = fromUser.statusBalance == 0
                ? "No status points left. Refills weekly or buy more."
                : "Not enough status points."
            return
        }

        let transaction = StatusTransaction(
            id: UUID().uuidString,
            fromUserId: fromUser.id,
            toUserId: toUserId,
            amount: amount,
            createdAt: .now,
            expiresAt: .now.addingTimeInterval(StatusTransaction.decayWindowDays),
            weightedValue: Double(amount) * statusWeight(for: fromUser)
        )

        // Write transaction
        try db.collection("statusTransactions").document(transaction.id).setData(from: transaction)

        // Debit sender's balance
        try await db.collection("users").document(fromUser.id).updateData([
            "statusBalance": FieldValue.increment(Int64(-amount))
        ])

        // Credit receiver's weighted score
        try await db.collection("users").document(toUserId).updateData([
            "totalStatusReceived": FieldValue.increment(transaction.weightedValue)
        ])
    }

    func statusWeight(for user: User) -> Double {
        let base = max(1.0, user.totalStatusReceived)
        return log2(base + 1)
    }

    // MARK: - Weekly Refill

    func refillIfNeeded(user: User) async throws {
        let calendar = Calendar.current
        let lastRefill = calendar.startOfDay(for: user.lastRefillDate)
        let today = calendar.startOfDay(for: .now)

        guard let daysSince = calendar.dateComponents([.day], from: lastRefill, to: today).day,
              daysSince >= 7 else { return }

        try await db.collection("users").document(user.id).updateData([
            "statusBalance": FieldValue.increment(Int64(user.weeklyRefillAmount)),
            "lastRefillDate": Timestamp(date: today)
        ])
    }

    // MARK: - Leaderboard

    func fetchLeaderboard(scope: LeaderboardScope, limit: Int = 50) async throws -> [LeaderboardEntry] {
        let docs = try await db.collection("users")
            .order(by: "totalStatusReceived", descending: true)
            .limit(to: limit)
            .getDocuments()

        return docs.documents.enumerated().compactMap { index, doc in
            guard let user = try? doc.data(as: User.self) else { return nil }
            return LeaderboardEntry(
                userId: user.id,
                username: user.username,
                displayName: user.displayName,
                avatarURL: user.avatarURL,
                rank: index + 1,
                weightedScore: user.totalStatusReceived,
                changeFromLastWeek: 0 // TODO: compute from weekly snapshots
            )
        }
    }

    // MARK: - Broadcast Eligibility

    func broadcastAudience(for userId: String, excluding blockedIds: Set<String> = []) -> [String] {
        let active = transactions.filter { !$0.isExpired }
        let directAudience = Set(active.filter { $0.toUserId == userId }.map { $0.fromUserId })

        var fullAudience = directAudience
        for member in directAudience {
            let transitive = active.filter { $0.toUserId == member }.map { $0.fromUserId }
            fullAudience.formUnion(transitive)
        }

        fullAudience.remove(userId)
        fullAudience.subtract(blockedIds)
        return Array(fullAudience)
    }

    func canBroadcast(user: User) -> Bool {
        guard let lastBroadcast = user.lastBroadcastDate else { return true }
        return !Calendar.current.isDate(lastBroadcast, inSameDayAs: .now)
    }

    // MARK: - User Search

    func searchUsers(query: String) async throws -> [User] {
        guard !query.isEmpty else { return [] }
        let lowered = query.lowercased()
        // Firestore doesn't support full-text search, so we use prefix matching
        let docs = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: lowered)
            .whereField("username", isLessThanOrEqualTo: lowered + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
        return docs.documents.compactMap { try? $0.data(as: User.self) }
    }

    // MARK: - Discovery

    func fetchSuggestedUsers(currentUserId: String, limit: Int = 20) async throws -> [User] {
        // Show recently active users sorted by status received
        let docs = try await db.collection("users")
            .order(by: "totalStatusReceived", descending: true)
            .limit(to: limit + 1)
            .getDocuments()
        return docs.documents
            .compactMap { try? $0.data(as: User.self) }
            .filter { $0.id != currentUserId }
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

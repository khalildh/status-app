import Testing
@testable import Status

@Suite("StatusEngine")
struct StatusEngineTests {

    // MARK: - Helpers

    private func makeUser(id: String, statusReceived: Double = 0) -> User {
        User(
            id: id,
            username: id,
            displayName: id,
            joinedAt: .now,
            statusBalance: 5,
            weeklyRefillAmount: 5,
            lastRefillDate: .now,
            totalStatusReceived: statusReceived,
            broadcastsToday: 0
        )
    }

    private func makeEngine(transactions: [StatusTransaction] = []) -> StatusEngine {
        let engine = StatusEngine()
        engine.transactions = transactions
        return engine
    }

    // MARK: - canMessage: Status Comparison

    @Test("Higher status user can message lower status user")
    func messageDown() {
        let engine = makeEngine()
        let high = makeUser(id: "high", statusReceived: 100)
        let low = makeUser(id: "low", statusReceived: 10)

        #expect(engine.canMessage(from: high, to: low))
    }

    @Test("Lower status user cannot message higher status user without path")
    func cannotMessageUpWithoutPath() {
        let engine = makeEngine()
        let high = makeUser(id: "high", statusReceived: 100)
        let low = makeUser(id: "low", statusReceived: 10)

        #expect(!engine.canMessage(from: low, to: high))
    }

    @Test("Equal status users cannot message without path")
    func equalStatusNoPath() {
        let engine = makeEngine()
        let a = makeUser(id: "a", statusReceived: 50)
        let b = makeUser(id: "b", statusReceived: 50)

        #expect(!engine.canMessage(from: a, to: b))
    }

    // MARK: - canMessage: Direct Path

    @Test("Direct status gift creates messaging path")
    func directPath() {
        let engine = makeEngine(transactions: [
            .mock(from: "low", to: "high", amount: 1)
        ])
        let low = makeUser(id: "low", statusReceived: 10)
        let high = makeUser(id: "high", statusReceived: 100)

        #expect(engine.canMessage(from: low, to: high))
    }

    // MARK: - canMessage: Transitive Path

    @Test("Transitive path through intermediary enables messaging")
    func transitivePath() {
        let engine = makeEngine(transactions: [
            .mock(from: "a", to: "b", amount: 1),
            .mock(from: "b", to: "c", amount: 1),
        ])
        let a = makeUser(id: "a", statusReceived: 10)
        let c = makeUser(id: "c", statusReceived: 100)

        #expect(engine.canMessage(from: a, to: c))
    }

    @Test("No transitive path when chain is broken")
    func noTransitivePath() {
        let engine = makeEngine(transactions: [
            .mock(from: "a", to: "b", amount: 1),
            // b did NOT give status to c
        ])
        let a = makeUser(id: "a", statusReceived: 10)
        let c = makeUser(id: "c", statusReceived: 100)

        #expect(!engine.canMessage(from: a, to: c))
    }

    // MARK: - canMessage: Expired Transactions

    @Test("Expired transactions don't count for messaging paths")
    func expiredTransactions() {
        let expired = StatusTransaction(
            id: "expired",
            fromUserId: "a",
            toUserId: "b",
            amount: 1,
            createdAt: .now.addingTimeInterval(-100 * 86400),
            expiresAt: .now.addingTimeInterval(-10 * 86400), // Already expired
            weightedValue: 1.0
        )
        let engine = makeEngine(transactions: [expired])
        let a = makeUser(id: "a", statusReceived: 10)
        let b = makeUser(id: "b", statusReceived: 100)

        #expect(!engine.canMessage(from: a, to: b))
    }

    // MARK: - canMessage: Block Enforcement

    @Test("Blocked users cannot message each other")
    func blockedCannotMessage() {
        let engine = makeEngine()
        let high = makeUser(id: "high", statusReceived: 100)
        let low = makeUser(id: "low", statusReceived: 10)

        // high has more status, normally can message low
        #expect(engine.canMessage(from: high, to: low, blockedIds: []))
        // but not if blocked
        #expect(!engine.canMessage(from: high, to: low, blockedIds: ["high"]))
        #expect(!engine.canMessage(from: high, to: low, blockedIds: ["low"]))
    }

    // MARK: - Broadcast Audience

    @Test("Broadcast audience includes people who gave you status")
    func broadcastAudienceDirect() {
        let engine = makeEngine(transactions: [
            .mock(from: "fan1", to: "creator", amount: 1),
            .mock(from: "fan2", to: "creator", amount: 2),
        ])

        let audience = engine.broadcastAudience(for: "creator")
        #expect(Set(audience) == Set(["fan1", "fan2"]))
    }

    @Test("Broadcast audience includes transitive connections")
    func broadcastAudienceTransitive() {
        let engine = makeEngine(transactions: [
            .mock(from: "fan", to: "creator", amount: 1),
            .mock(from: "superfan", to: "fan", amount: 1),
        ])

        let audience = engine.broadcastAudience(for: "creator")
        #expect(Set(audience) == Set(["fan", "superfan"]))
    }

    @Test("Broadcast audience excludes self")
    func broadcastExcludesSelf() {
        let engine = makeEngine(transactions: [
            .mock(from: "creator", to: "creator", amount: 1), // self-give edge case
        ])

        let audience = engine.broadcastAudience(for: "creator")
        #expect(!audience.contains("creator"))
    }

    @Test("Broadcast audience excludes blocked users")
    func broadcastExcludesBlocked() {
        let engine = makeEngine(transactions: [
            .mock(from: "fan1", to: "creator", amount: 1),
            .mock(from: "fan2", to: "creator", amount: 2),
        ])

        let audience = engine.broadcastAudience(for: "creator", excluding: ["fan1"])
        #expect(audience == ["fan2"])
    }

    // MARK: - canBroadcast

    @Test("User with no previous broadcast can broadcast")
    func canBroadcastFirstTime() {
        let engine = makeEngine()
        let user = makeUser(id: "a")
        #expect(engine.canBroadcast(user: user))
    }

    @Test("User who broadcast today cannot broadcast again")
    func cannotBroadcastTwice() {
        let engine = makeEngine()
        var user = makeUser(id: "a")
        user.lastBroadcastDate = .now
        user.broadcastsToday = 1
        #expect(!engine.canBroadcast(user: user))
    }

    @Test("User who broadcast yesterday can broadcast today")
    func canBroadcastNextDay() {
        let engine = makeEngine()
        var user = makeUser(id: "a")
        user.lastBroadcastDate = .now.addingTimeInterval(-86400)
        #expect(engine.canBroadcast(user: user))
    }

    // MARK: - Status Weight

    @Test("Status weight uses logarithmic scaling")
    func statusWeightScaling() {
        let engine = makeEngine()
        let low = makeUser(id: "low", statusReceived: 1)
        let mid = makeUser(id: "mid", statusReceived: 100)
        let high = makeUser(id: "high", statusReceived: 10000)

        let lowWeight = engine.statusWeight(for: low)
        let midWeight = engine.statusWeight(for: mid)
        let highWeight = engine.statusWeight(for: high)

        // Weights should increase but with diminishing returns
        #expect(lowWeight > 0)
        #expect(midWeight > lowWeight)
        #expect(highWeight > midWeight)
        // Log scaling means 100x more status doesn't give 100x weight
        #expect(highWeight / lowWeight < 20)
    }

    // MARK: - Transaction Decay

    @Test("Transaction within 90 days is active")
    func activeTransaction() {
        let tx = StatusTransaction.mock(from: "a", to: "b", amount: 1, daysAgo: 30)
        #expect(!tx.isExpired)
    }

    @Test("Transaction older than 90 days is expired")
    func expiredTransaction() {
        let tx = StatusTransaction(
            id: "old",
            fromUserId: "a",
            toUserId: "b",
            amount: 1,
            createdAt: .now.addingTimeInterval(-100 * 86400),
            expiresAt: .now.addingTimeInterval(-10 * 86400),
            weightedValue: 1.0
        )
        #expect(tx.isExpired)
    }
}

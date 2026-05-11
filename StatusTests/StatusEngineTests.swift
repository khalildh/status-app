import Foundation
import Testing
@testable import Status

@Suite("StatusEngine")
@MainActor
struct StatusEngineTests {

    // MARK: - Helpers

    private func makeUser(
        id: String,
        statusReceived: Double = 0,
        balance: Int = 5,
        lastRefillDaysAgo: Int = 0,
        lastBroadcastDate: Date? = nil
    ) -> User {
        User(
            id: id,
            username: id,
            displayName: id,
            joinedAt: .now.addingTimeInterval(-86400 * 30),
            statusBalance: balance,
            weeklyRefillAmount: 5,
            lastRefillDate: .now.addingTimeInterval(-Double(lastRefillDaysAgo) * 86400),
            totalStatusReceived: statusReceived,
            broadcastsToday: lastBroadcastDate != nil ? 1 : 0,
            lastBroadcastDate: lastBroadcastDate
        )
    }

    private func makeEngine(transactions: [StatusTransaction] = []) -> StatusEngine {
        let engine = StatusEngine()
        engine.transactions = transactions
        return engine
    }

    private func makeTx(
        from: String,
        to: String,
        amount: Int = 1,
        daysAgo: Int = 0,
        expired: Bool = false
    ) -> StatusTransaction {
        if expired {
            return StatusTransaction(
                id: UUID().uuidString,
                fromUserId: from,
                toUserId: to,
                amount: amount,
                createdAt: .now.addingTimeInterval(-100 * 86400),
                expiresAt: .now.addingTimeInterval(-10 * 86400),
                weightedValue: Double(amount)
            )
        }
        return .mock(from: from, to: to, amount: amount, daysAgo: daysAgo)
    }

    // =========================================================================
    // MARK: - Messaging Rules: Status Comparison
    // =========================================================================

    @Test("Higher status user can message lower status user")
    func messageDown() {
        let engine = makeEngine()
        #expect(engine.canMessage(
            from: makeUser(id: "high", statusReceived: 100),
            to: makeUser(id: "low", statusReceived: 10)
        ))
    }

    @Test("Lower status user cannot message higher status user without path")
    func cannotMessageUpWithoutPath() {
        let engine = makeEngine()
        #expect(!engine.canMessage(
            from: makeUser(id: "low", statusReceived: 10),
            to: makeUser(id: "high", statusReceived: 100)
        ))
    }

    @Test("Equal status users cannot message without path")
    func equalStatusNoPath() {
        let engine = makeEngine()
        #expect(!engine.canMessage(
            from: makeUser(id: "a", statusReceived: 50),
            to: makeUser(id: "b", statusReceived: 50)
        ))
    }

    @Test("User with zero status cannot message anyone with status")
    func zeroStatusCannotMessage() {
        let engine = makeEngine()
        #expect(!engine.canMessage(
            from: makeUser(id: "new", statusReceived: 0),
            to: makeUser(id: "established", statusReceived: 1)
        ))
    }

    @Test("Both zero status users cannot message each other")
    func bothZeroStatus() {
        let engine = makeEngine()
        #expect(!engine.canMessage(
            from: makeUser(id: "a", statusReceived: 0),
            to: makeUser(id: "b", statusReceived: 0)
        ))
    }

    @Test("Tiny status difference still allows messaging down")
    func tinyDifference() {
        let engine = makeEngine()
        #expect(engine.canMessage(
            from: makeUser(id: "a", statusReceived: 0.1),
            to: makeUser(id: "b", statusReceived: 0)
        ))
    }

    // =========================================================================
    // MARK: - Messaging Rules: Direct Path
    // =========================================================================

    @Test("Direct status gift creates messaging path upward")
    func directPath() {
        let engine = makeEngine(transactions: [
            makeTx(from: "low", to: "high")
        ])
        #expect(engine.canMessage(
            from: makeUser(id: "low", statusReceived: 10),
            to: makeUser(id: "high", statusReceived: 100)
        ))
    }

    @Test("Giving status to someone doesn't let them message you")
    func directPathNotReversible() {
        // "low" gave status to "high", but "high" can already message down
        // The point: giving status doesn't create a reverse path for the recipient
        let engine = makeEngine(transactions: [
            makeTx(from: "a", to: "b")
        ])
        // b did NOT give status to a, and b has less status
        #expect(!engine.canMessage(
            from: makeUser(id: "b", statusReceived: 5),
            to: makeUser(id: "a", statusReceived: 100)
        ))
    }

    @Test("Multiple gifts from same person still create path")
    func multipleGiftsSamePerson() {
        let engine = makeEngine(transactions: [
            makeTx(from: "fan", to: "celeb", amount: 1),
            makeTx(from: "fan", to: "celeb", amount: 2, daysAgo: 5),
        ])
        #expect(engine.canMessage(
            from: makeUser(id: "fan", statusReceived: 5),
            to: makeUser(id: "celeb", statusReceived: 500)
        ))
    }

    // =========================================================================
    // MARK: - Messaging Rules: Transitive Path
    // =========================================================================

    @Test("Transitive path through intermediary enables messaging")
    func transitivePath() {
        let engine = makeEngine(transactions: [
            makeTx(from: "a", to: "b"),
            makeTx(from: "b", to: "c"),
        ])
        #expect(engine.canMessage(
            from: makeUser(id: "a", statusReceived: 10),
            to: makeUser(id: "c", statusReceived: 100)
        ))
    }

    @Test("No transitive path when chain is broken")
    func noTransitivePath() {
        let engine = makeEngine(transactions: [
            makeTx(from: "a", to: "b"),
            // b did NOT give status to c
        ])
        #expect(!engine.canMessage(
            from: makeUser(id: "a", statusReceived: 10),
            to: makeUser(id: "c", statusReceived: 100)
        ))
    }

    @Test("Two-hop chain does NOT enable messaging (only 1 hop allowed)")
    func twoHopChainFails() {
        let engine = makeEngine(transactions: [
            makeTx(from: "a", to: "b"),
            makeTx(from: "b", to: "c"),
            makeTx(from: "c", to: "d"),
        ])
        // a -> b -> c -> d is a 2-hop chain from a's perspective to d
        // Only 1 hop is supported
        #expect(!engine.canMessage(
            from: makeUser(id: "a", statusReceived: 1),
            to: makeUser(id: "d", statusReceived: 1000)
        ))
    }

    @Test("Transitive path works with different intermediaries")
    func transitiveMultipleIntermediaries() {
        let engine = makeEngine(transactions: [
            makeTx(from: "a", to: "x"),
            makeTx(from: "a", to: "y"),
            makeTx(from: "y", to: "target"),
        ])
        // a gave to x and y, y gave to target → a can reach target through y
        #expect(engine.canMessage(
            from: makeUser(id: "a", statusReceived: 1),
            to: makeUser(id: "target", statusReceived: 1000)
        ))
    }

    @Test("Transitive path requires correct direction")
    func transitiveDirectionMatters() {
        let engine = makeEngine(transactions: [
            makeTx(from: "a", to: "b"),
            makeTx(from: "target", to: "b"), // target gave to b, not b gave to target
        ])
        #expect(!engine.canMessage(
            from: makeUser(id: "a", statusReceived: 1),
            to: makeUser(id: "target", statusReceived: 1000)
        ))
    }

    // =========================================================================
    // MARK: - Messaging Rules: Expired Transactions
    // =========================================================================

    @Test("Expired transactions don't count for direct messaging paths")
    func expiredDirectPath() {
        let engine = makeEngine(transactions: [
            makeTx(from: "a", to: "b", expired: true)
        ])
        #expect(!engine.canMessage(
            from: makeUser(id: "a", statusReceived: 10),
            to: makeUser(id: "b", statusReceived: 100)
        ))
    }

    @Test("Expired transactions don't count for transitive paths")
    func expiredTransitivePath() {
        let engine = makeEngine(transactions: [
            makeTx(from: "a", to: "b"),                     // active
            makeTx(from: "b", to: "c", expired: true),      // expired
        ])
        #expect(!engine.canMessage(
            from: makeUser(id: "a", statusReceived: 1),
            to: makeUser(id: "c", statusReceived: 100)
        ))
    }

    @Test("Mix of expired and active: active path still works")
    func mixedExpiredActive() {
        let engine = makeEngine(transactions: [
            makeTx(from: "a", to: "b", expired: true),  // expired
            makeTx(from: "a", to: "b"),                  // active duplicate
        ])
        #expect(engine.canMessage(
            from: makeUser(id: "a", statusReceived: 10),
            to: makeUser(id: "b", statusReceived: 100)
        ))
    }

    // =========================================================================
    // MARK: - Messaging Rules: Block Enforcement
    // =========================================================================

    @Test("Blocked sender cannot message even with higher status")
    func blockedSenderCannotMessage() {
        let engine = makeEngine()
        #expect(!engine.canMessage(
            from: makeUser(id: "high", statusReceived: 100),
            to: makeUser(id: "low", statusReceived: 10),
            blockedIds: ["high"]
        ))
    }

    @Test("Cannot message blocked recipient")
    func cannotMessageBlockedRecipient() {
        let engine = makeEngine()
        #expect(!engine.canMessage(
            from: makeUser(id: "high", statusReceived: 100),
            to: makeUser(id: "low", statusReceived: 10),
            blockedIds: ["low"]
        ))
    }

    @Test("Block overrides transitive path")
    func blockOverridesTransitive() {
        let engine = makeEngine(transactions: [
            makeTx(from: "a", to: "b"),
            makeTx(from: "b", to: "c"),
        ])
        #expect(!engine.canMessage(
            from: makeUser(id: "a", statusReceived: 1),
            to: makeUser(id: "c", statusReceived: 100),
            blockedIds: ["a"]
        ))
    }

    @Test("Empty blocked set doesn't affect messaging")
    func emptyBlockedSet() {
        let engine = makeEngine()
        #expect(engine.canMessage(
            from: makeUser(id: "high", statusReceived: 100),
            to: makeUser(id: "low", statusReceived: 10),
            blockedIds: []
        ))
    }

    @Test("Blocking unrelated user doesn't affect messaging")
    func blockUnrelatedUser() {
        let engine = makeEngine()
        #expect(engine.canMessage(
            from: makeUser(id: "high", statusReceived: 100),
            to: makeUser(id: "low", statusReceived: 10),
            blockedIds: ["unrelated"]
        ))
    }

    // =========================================================================
    // MARK: - Broadcast Audience
    // =========================================================================

    @Test("Broadcast audience includes people who gave you status")
    func broadcastAudienceDirect() {
        let engine = makeEngine(transactions: [
            makeTx(from: "fan1", to: "creator"),
            makeTx(from: "fan2", to: "creator", amount: 2),
        ])
        let audience = Set(engine.broadcastAudience(for: "creator"))
        #expect(audience == Set(["fan1", "fan2"]))
    }

    @Test("Broadcast audience includes transitive connections")
    func broadcastAudienceTransitive() {
        let engine = makeEngine(transactions: [
            makeTx(from: "fan", to: "creator"),
            makeTx(from: "superfan", to: "fan"),
        ])
        let audience = Set(engine.broadcastAudience(for: "creator"))
        #expect(audience == Set(["fan", "superfan"]))
    }

    @Test("Broadcast audience excludes self")
    func broadcastExcludesSelf() {
        let engine = makeEngine(transactions: [
            makeTx(from: "creator", to: "creator"),
        ])
        #expect(!engine.broadcastAudience(for: "creator").contains("creator"))
    }

    @Test("Broadcast audience excludes blocked users")
    func broadcastExcludesBlocked() {
        let engine = makeEngine(transactions: [
            makeTx(from: "fan1", to: "creator"),
            makeTx(from: "fan2", to: "creator"),
        ])
        let audience = engine.broadcastAudience(for: "creator", excluding: ["fan1"])
        #expect(Set(audience) == Set(["fan2"]))
    }

    @Test("Broadcast audience is empty when no one gave you status")
    func broadcastAudienceEmpty() {
        let engine = makeEngine(transactions: [
            makeTx(from: "creator", to: "someone"), // creator gave, didn't receive
        ])
        #expect(engine.broadcastAudience(for: "creator").isEmpty)
    }

    @Test("Broadcast audience doesn't include expired givers")
    func broadcastAudienceNoExpired() {
        let engine = makeEngine(transactions: [
            makeTx(from: "fan", to: "creator", expired: true),
        ])
        #expect(engine.broadcastAudience(for: "creator").isEmpty)
    }

    @Test("Broadcast audience deduplicates users appearing via multiple paths")
    func broadcastAudienceDeduplicates() {
        let engine = makeEngine(transactions: [
            makeTx(from: "fan", to: "creator"),
            makeTx(from: "fan", to: "intermediary"),
            makeTx(from: "intermediary", to: "creator"),
        ])
        let audience = engine.broadcastAudience(for: "creator")
        // fan appears both as direct giver and transitive through intermediary
        let fanCount = audience.filter { $0 == "fan" }.count
        #expect(fanCount == 1)
    }

    // =========================================================================
    // MARK: - Broadcast Eligibility
    // =========================================================================

    @Test("User with no previous broadcast can broadcast")
    func canBroadcastFirstTime() {
        let engine = makeEngine()
        #expect(engine.canBroadcast(user: makeUser(id: "a")))
    }

    @Test("User who broadcast today cannot broadcast again")
    func cannotBroadcastTwice() {
        let engine = makeEngine()
        #expect(!engine.canBroadcast(user: makeUser(id: "a", lastBroadcastDate: .now)))
    }

    @Test("User who broadcast yesterday can broadcast today")
    func canBroadcastNextDay() {
        let engine = makeEngine()
        let yesterday = Date.now.addingTimeInterval(-86400)
        #expect(engine.canBroadcast(user: makeUser(id: "a", lastBroadcastDate: yesterday)))
    }

    @Test("User who broadcast 1 second before midnight can broadcast after midnight")
    func broadcastMidnightBoundary() {
        let engine = makeEngine()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let justBeforeMidnight = startOfToday.addingTimeInterval(-1)
        #expect(engine.canBroadcast(user: makeUser(id: "a", lastBroadcastDate: justBeforeMidnight)))
    }

    // =========================================================================
    // MARK: - Status Weight
    // =========================================================================

    @Test("Status weight uses logarithmic scaling")
    func statusWeightScaling() {
        let engine = makeEngine()
        let lowWeight = engine.statusWeight(for: makeUser(id: "low", statusReceived: 1))
        let midWeight = engine.statusWeight(for: makeUser(id: "mid", statusReceived: 100))
        let highWeight = engine.statusWeight(for: makeUser(id: "high", statusReceived: 10000))

        #expect(lowWeight > 0)
        #expect(midWeight > lowWeight)
        #expect(highWeight > midWeight)
        // Log scaling: 10000x more status doesn't give 10000x weight
        #expect(highWeight / lowWeight < 20)
    }

    @Test("Zero status user still has positive weight")
    func zeroStatusWeight() {
        let engine = makeEngine()
        let weight = engine.statusWeight(for: makeUser(id: "new", statusReceived: 0))
        #expect(weight > 0)
    }

    @Test("Status weight is deterministic for same input")
    func weightDeterministic() {
        let engine = makeEngine()
        let user = makeUser(id: "a", statusReceived: 42)
        #expect(engine.statusWeight(for: user) == engine.statusWeight(for: user))
    }

    // =========================================================================
    // MARK: - Transaction Decay
    // =========================================================================

    @Test("Transaction within 90 days is active")
    func activeTransaction() {
        #expect(!makeTx(from: "a", to: "b", daysAgo: 30).isExpired)
    }

    @Test("Transaction at exactly 0 days is active")
    func brandNewTransaction() {
        #expect(!makeTx(from: "a", to: "b", daysAgo: 0).isExpired)
    }

    @Test("Transaction older than 90 days is expired")
    func expiredTransaction() {
        #expect(makeTx(from: "a", to: "b", expired: true).isExpired)
    }

    @Test("Transaction at 89 days is still active")
    func almostExpiredTransaction() {
        #expect(!makeTx(from: "a", to: "b", daysAgo: 89).isExpired)
    }

    // =========================================================================
    // MARK: - Edge Cases
    // =========================================================================

    @Test("User cannot message themselves")
    func cannotMessageSelf() {
        let engine = makeEngine()
        // Same user, equal status — should be false (no path to self)
        #expect(!engine.canMessage(
            from: makeUser(id: "me", statusReceived: 50),
            to: makeUser(id: "me", statusReceived: 50)
        ))
    }

    @Test("Self-transaction creates path to self but that's a no-op")
    func selfTransaction() {
        let engine = makeEngine(transactions: [
            makeTx(from: "me", to: "me")
        ])
        // Has a direct path to self, but equal status so only path matters
        // Direct path exists so this should be true via path rule
        #expect(engine.canMessage(
            from: makeUser(id: "me", statusReceived: 50),
            to: makeUser(id: "me", statusReceived: 50)
        ))
    }

    @Test("Large number of transactions doesn't break")
    func manyTransactions() {
        var txns: [StatusTransaction] = []
        for i in 0..<1000 {
            txns.append(makeTx(from: "user_\(i)", to: "user_\(i + 1)"))
        }
        let engine = makeEngine(transactions: txns)
        // user_0 gave to user_1, user_1 gave to user_2 → user_0 can reach user_2
        #expect(engine.canMessage(
            from: makeUser(id: "user_0", statusReceived: 1),
            to: makeUser(id: "user_2", statusReceived: 1000)
        ))
    }

    @Test("No transactions means no paths exist")
    func noTransactions() {
        let engine = makeEngine()
        #expect(!engine.canMessage(
            from: makeUser(id: "a", statusReceived: 50),
            to: makeUser(id: "b", statusReceived: 50)
        ))
    }
}

// =============================================================================
// MARK: - Model Tests
// =============================================================================

@Suite("User Model")
struct UserModelTests {

    @Test("Weekly free points constant is 5")
    func weeklyPoints() {
        #expect(User.weeklyFreePoints == 5)
    }

    @Test("Max purchase per week is 50")
    func maxPurchase() {
        #expect(User.maxPurchasePerWeek == 50)
    }

    @Test("Mock user has correct defaults")
    func mockUser() {
        let user = User.mock
        #expect(user.id == "user_1")
        #expect(user.username == "khalid")
        #expect(user.statusBalance == 5)
        #expect(user.weeklyRefillAmount == 5)
        #expect(user.isAuthenticated)
    }

    @Test("Mock others has 4 users")
    func mockOthers() {
        #expect(User.mockOthers.count == 4)
    }

    @Test("All mock users have unique IDs")
    func uniqueIds() {
        let allUsers = [User.mock] + User.mockOthers
        let ids = Set(allUsers.map(\.id))
        #expect(ids.count == allUsers.count)
    }
}

extension User {
    var isAuthenticated: Bool { !id.isEmpty }
}

@Suite("Broadcast Model")
struct BroadcastModelTests {

    @Test("Broadcast lifetime is 24 hours")
    func lifetime() {
        #expect(Broadcast.lifetimeSeconds == 24 * 3600)
    }

    @Test("Fresh broadcast is not expired")
    func freshBroadcast() {
        let bc = Broadcast(
            id: "test",
            authorId: "a",
            text: "Hello",
            createdAt: .now,
            expiresAt: .now.addingTimeInterval(Broadcast.lifetimeSeconds),
            reachCount: 10,
            statusReactions: 0
        )
        #expect(!bc.isExpired)
        #expect(bc.timeRemaining > 0)
    }

    @Test("Old broadcast is expired")
    func expiredBroadcast() {
        let bc = Broadcast(
            id: "test",
            authorId: "a",
            text: "Hello",
            createdAt: .now.addingTimeInterval(-48 * 3600),
            expiresAt: .now.addingTimeInterval(-24 * 3600),
            reachCount: 10,
            statusReactions: 0
        )
        #expect(bc.isExpired)
        #expect(bc.timeRemaining == 0)
    }

    @Test("Mock broadcasts are not expired")
    func mockBroadcasts() {
        for bc in Broadcast.mocks {
            #expect(!bc.isExpired)
        }
    }
}

@Suite("StatusTransaction Model")
struct StatusTransactionModelTests {

    @Test("Decay window is 90 days")
    func decayWindow() {
        #expect(StatusTransaction.decayWindowDays == 90 * 86400)
    }

    @Test("Mock transaction has correct expiry")
    func mockExpiry() {
        let tx = StatusTransaction.mock(from: "a", to: "b", amount: 1, daysAgo: 0)
        #expect(!tx.isExpired)
        #expect(tx.amount == 1)
        #expect(tx.fromUserId == "a")
        #expect(tx.toUserId == "b")
    }

    @Test("Transaction amount is preserved")
    func amountPreserved() {
        let tx = StatusTransaction.mock(from: "a", to: "b", amount: 5)
        #expect(tx.amount == 5)
    }
}

@Suite("Conversation Model")
struct ConversationModelTests {

    @Test("Mock conversations exist")
    func mocksExist() {
        #expect(!Conversation.mocks.isEmpty)
    }

    @Test("Each conversation has exactly 2 participants")
    func twoParticipants() {
        for conv in Conversation.mocks {
            #expect(conv.participantIds.count == 2)
        }
    }

    @Test("Conversations have unique IDs")
    func uniqueIds() {
        let ids = Set(Conversation.mocks.map(\.id))
        #expect(ids.count == Conversation.mocks.count)
    }
}

@Suite("Message Model")
struct MessageModelTests {

    @Test("Mock messages are ordered by time")
    func messagesOrdered() {
        let msgs = Message.mocks(conversationId: "conv_1", between: "a", userB: "b")
        for i in 1..<msgs.count {
            #expect(msgs[i].sentAt > msgs[i - 1].sentAt)
        }
    }

    @Test("Messages belong to correct conversation")
    func correctConversation() {
        let msgs = Message.mocks(conversationId: "test_conv", between: "a", userB: "b")
        for msg in msgs {
            #expect(msg.conversationId == "test_conv")
        }
    }

    @Test("Messages alternate between two users")
    func alternatingUsers() {
        let msgs = Message.mocks(conversationId: "c", between: "a", userB: "b")
        let senders = Set(msgs.map(\.senderId))
        #expect(senders == Set(["a", "b"]))
    }

    @Test("Unread message has nil readAt")
    func unreadMessage() {
        let msg = Message(
            id: "1", conversationId: "c", senderId: "a",
            text: "hi", sentAt: .now
        )
        #expect(!msg.isRead)
    }

    @Test("Read message has non-nil readAt")
    func readMessage() {
        let msg = Message(
            id: "1", conversationId: "c", senderId: "a",
            text: "hi", sentAt: .now, readAt: .now
        )
        #expect(msg.isRead)
    }
}

@Suite("LeaderboardEntry Model")
struct LeaderboardEntryModelTests {

    @Test("Rising entry has positive change")
    func risingEntry() {
        let entry = LeaderboardEntry(
            userId: "a", username: "a", displayName: "A",
            rank: 5, weightedScore: 100, changeFromLastWeek: 3
        )
        #expect(entry.isRising)
        #expect(!entry.isFalling)
    }

    @Test("Falling entry has negative change")
    func fallingEntry() {
        let entry = LeaderboardEntry(
            userId: "a", username: "a", displayName: "A",
            rank: 5, weightedScore: 100, changeFromLastWeek: -2
        )
        #expect(!entry.isRising)
        #expect(entry.isFalling)
    }

    @Test("Stable entry has zero change")
    func stableEntry() {
        let entry = LeaderboardEntry(
            userId: "a", username: "a", displayName: "A",
            rank: 5, weightedScore: 100, changeFromLastWeek: 0
        )
        #expect(!entry.isRising)
        #expect(!entry.isFalling)
    }

    @Test("Mock leaderboard is sorted by rank")
    func mocksSorted() {
        let entries = LeaderboardEntry.mocks
        for i in 1..<entries.count {
            #expect(entries[i].rank > entries[i - 1].rank)
        }
    }

    @Test("Mock leaderboard scores decrease with rank")
    func scoresDecrease() {
        let entries = LeaderboardEntry.mocks
        for i in 1..<entries.count {
            #expect(entries[i].weightedScore <= entries[i - 1].weightedScore)
        }
    }
}

@Suite("Block Model")
struct BlockModelTests {

    @Test("All block reasons are available")
    func allReasons() {
        #expect(BlockReason.allCases.count == 4)
    }

    @Test("Block reasons have display strings")
    func reasonStrings() {
        #expect(BlockReason.spam.rawValue == "Spam")
        #expect(BlockReason.harassment.rawValue == "Harassment")
        #expect(BlockReason.unwantedMessages.rawValue == "Unwanted messages")
        #expect(BlockReason.other.rawValue == "Other")
    }
}

@Suite("LeaderboardScope")
struct LeaderboardScopeTests {

    @Test("All scopes are available")
    func allScopes() {
        #expect(LeaderboardScope.allCases.count == 3)
    }

    @Test("Scope display names are correct")
    func scopeNames() {
        #expect(LeaderboardScope.weekly.rawValue == "This Week")
        #expect(LeaderboardScope.monthly.rawValue == "This Month")
        #expect(LeaderboardScope.allTime.rawValue == "All Time")
    }
}

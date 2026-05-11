import Foundation
import Testing
@testable import Status

@Suite("LeaderboardService")
@MainActor
struct LeaderboardServiceTests {

    @Test("Initial state")
    func initialState() {
        let service = LeaderboardService()
        #expect(service.entries.isEmpty)
        #expect(service.currentScope == .weekly)
        #expect(!service.isLoading)
    }

    @Test("Preview has entries")
    func preview() {
        let service = LeaderboardService.preview
        #expect(!service.entries.isEmpty)
    }

    @Test("userRank finds user in entries")
    func findUser() {
        let service = LeaderboardService.preview
        let entry = service.userRank(userId: "user_1")
        #expect(entry != nil)
        #expect(entry?.username == "khalid")
    }

    @Test("userRank returns nil for unknown user")
    func unknownUser() {
        let service = LeaderboardService.preview
        #expect(service.userRank(userId: "nonexistent") == nil)
    }
}

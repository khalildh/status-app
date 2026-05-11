import Foundation
import Testing
@testable import Status

@Suite("BlockService")
@MainActor
struct BlockServiceTests {

    @Test("isBlocked returns false for empty set")
    func emptyBlocked() {
        let service = BlockService()
        #expect(!service.isBlocked("user_1"))
    }

    @Test("isBlocked returns true for blocked user")
    func blockedUser() {
        let service = BlockService()
        service.blockedUserIds = ["user_1", "user_2"]
        #expect(service.isBlocked("user_1"))
        #expect(service.isBlocked("user_2"))
    }

    @Test("isBlocked returns false for non-blocked user")
    func notBlocked() {
        let service = BlockService()
        service.blockedUserIds = ["user_1"]
        #expect(!service.isBlocked("user_2"))
    }

    @Test("Initial state is empty")
    func initialState() {
        let service = BlockService()
        #expect(service.blockedUserIds.isEmpty)
        #expect(!service.isLoading)
    }
}

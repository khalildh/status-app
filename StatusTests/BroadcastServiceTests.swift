import Foundation
import Testing
@testable import Status

@Suite("BroadcastService")
@MainActor
struct BroadcastServiceTests {

    @Test("Initial state")
    func initialState() {
        let service = BroadcastService()
        #expect(service.feed.isEmpty)
        #expect(!service.isLoading)
        #expect(service.error == nil)
    }

    @Test("Preview has mock data")
    func preview() {
        let service = BroadcastService.preview
        #expect(!service.feed.isEmpty)
    }
}

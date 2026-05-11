import Foundation
import Testing
@testable import Status

@Suite("MessageService")
@MainActor
struct MessageServiceTests {

    @Test("Initial state")
    func initialState() {
        let service = MessageService()
        #expect(service.conversations.isEmpty)
        #expect(service.messagesByConversation.isEmpty)
        #expect(!service.isLoading)
    }

    @Test("Preview has mock conversations")
    func preview() {
        let service = MessageService.preview
        #expect(!service.conversations.isEmpty)
        #expect(!service.messagesByConversation.isEmpty)
    }

    @Test("Preview conversations have messages")
    func previewMessages() {
        let service = MessageService.preview
        #expect(service.messagesByConversation["conv_1"] != nil)
        #expect(service.messagesByConversation["conv_1"]!.count > 0)
    }
}

import Foundation
import Testing
@testable import Status

@Suite("NotificationService")
@MainActor
struct NotificationServiceTests {

    @Test("Initial state has no FCM token")
    func initialState() {
        let service = NotificationService()
        #expect(service.fcmToken == nil)
    }

    @Test("Preview returns instance")
    func preview() {
        let service = NotificationService.preview
        #expect(service.fcmToken == nil)
    }
}

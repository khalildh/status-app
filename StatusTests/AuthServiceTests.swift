import Foundation
import Testing
@testable import Status

@Suite("AuthService")
@MainActor
struct AuthServiceTests {

    @Test("Preview is authenticated")
    func previewAuth() {
        let service = AuthService.preview
        #expect(service.isAuthenticated)
        #expect(service.currentUser != nil)
    }

    @Test("Preview user is mock user")
    func previewUser() {
        let service = AuthService.preview
        #expect(service.currentUser?.id == "user_1")
        #expect(service.currentUser?.username == "khalid")
    }

    @Test("Not authenticated when no user")
    func notAuthenticated() {
        let service = AuthService.preview
        service.currentUser = nil
        #expect(!service.isAuthenticated)
    }

    @Test("Initial loading state is false")
    func notLoading() {
        let service = AuthService.preview
        #expect(!service.isLoading)
    }

    @Test("Initial error is nil")
    func noError() {
        let service = AuthService.preview
        #expect(service.error == nil)
    }
}

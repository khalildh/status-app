import Foundation
import Testing
@testable import Status

@Suite("DeepLinkHandler")
struct DeepLinkHandlerTests {

    // MARK: - URL Parsing

    @Test("Handles profile deep link")
    func profileLink() {
        let handler = DeepLinkHandler()
        handler.handle(url: URL(string: "status://profile/user_123")!)
        #expect(handler.pendingRoute == .profile(userId: "user_123"))
    }

    @Test("Handles give deep link")
    func giveLink() {
        let handler = DeepLinkHandler()
        handler.handle(url: URL(string: "status://give/user_456")!)
        #expect(handler.pendingRoute == .give(userId: "user_456"))
    }

    @Test("Ignores unknown scheme")
    func unknownScheme() {
        let handler = DeepLinkHandler()
        handler.handle(url: URL(string: "https://example.com/profile/user_1")!)
        #expect(handler.pendingRoute == nil)
    }

    @Test("Ignores unknown host")
    func unknownHost() {
        let handler = DeepLinkHandler()
        handler.handle(url: URL(string: "status://unknown/user_1")!)
        #expect(handler.pendingRoute == nil)
    }

    @Test("Ignores profile link with no user ID")
    func profileNoUserId() {
        let handler = DeepLinkHandler()
        handler.handle(url: URL(string: "status://profile")!)
        #expect(handler.pendingRoute == nil)
    }

    @Test("Ignores give link with no user ID")
    func giveNoUserId() {
        let handler = DeepLinkHandler()
        handler.handle(url: URL(string: "status://give")!)
        #expect(handler.pendingRoute == nil)
    }

    // MARK: - Consume Route

    @Test("consumeRoute returns and clears pending route")
    func consumeRoute() {
        let handler = DeepLinkHandler()
        handler.handle(url: URL(string: "status://profile/abc")!)
        let route = handler.consumeRoute()
        #expect(route == .profile(userId: "abc"))
        #expect(handler.pendingRoute == nil)
    }

    @Test("consumeRoute returns nil when no pending route")
    func consumeRouteNil() {
        let handler = DeepLinkHandler()
        #expect(handler.consumeRoute() == nil)
    }

    @Test("Second handle overwrites first")
    func overwrite() {
        let handler = DeepLinkHandler()
        handler.handle(url: URL(string: "status://profile/first")!)
        handler.handle(url: URL(string: "status://give/second")!)
        #expect(handler.pendingRoute == .give(userId: "second"))
    }

    // MARK: - URL Generation

    @Test("profileURL generates correct URL")
    func profileURL() {
        let url = DeepLinkHandler.profileURL(userId: "user_99")
        #expect(url.scheme == "status")
        #expect(url.host == "profile")
        #expect(url.absoluteString == "status://profile/user_99")
    }

    @Test("giveURL generates correct URL")
    func giveURL() {
        let url = DeepLinkHandler.giveURL(userId: "user_42")
        #expect(url.scheme == "status")
        #expect(url.host == "give")
        #expect(url.absoluteString == "status://give/user_42")
    }

    // MARK: - DeepRoute Equatable

    @Test("Same routes are equal")
    func routeEquality() {
        #expect(DeepLinkHandler.DeepRoute.profile(userId: "a") == DeepLinkHandler.DeepRoute.profile(userId: "a"))
        #expect(DeepLinkHandler.DeepRoute.give(userId: "b") == DeepLinkHandler.DeepRoute.give(userId: "b"))
    }

    @Test("Different routes are not equal")
    func routeInequality() {
        #expect(DeepLinkHandler.DeepRoute.profile(userId: "a") != DeepLinkHandler.DeepRoute.give(userId: "a"))
        #expect(DeepLinkHandler.DeepRoute.profile(userId: "a") != DeepLinkHandler.DeepRoute.profile(userId: "b"))
    }
}

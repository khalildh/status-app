import Foundation

/// Handles URL scheme: status://profile/{userId}, status://give/{userId}
@Observable
final class DeepLinkHandler {
    var pendingRoute: DeepRoute?

    enum DeepRoute: Equatable {
        case profile(userId: String)
        case give(userId: String)
    }

    func handle(url: URL) {
        guard url.scheme == "status" else { return }

        switch url.host {
        case "profile":
            if let userId = url.pathComponents.dropFirst().first {
                pendingRoute = .profile(userId: userId)
            }
        case "give":
            if let userId = url.pathComponents.dropFirst().first {
                pendingRoute = .give(userId: userId)
            }
        default:
            break
        }
    }

    func consumeRoute() -> DeepRoute? {
        let route = pendingRoute
        pendingRoute = nil
        return route
    }

    /// Generate a shareable profile URL
    static func profileURL(userId: String) -> URL {
        URL(string: "status://profile/\(userId)")!
    }

    /// Generate a "give status" invite URL
    static func giveURL(userId: String) -> URL {
        URL(string: "status://give/\(userId)")!
    }
}

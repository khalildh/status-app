import Foundation

@Observable
final class BroadcastService {
    var feed: [Broadcast] = []
    var isLoading = false
    var error: String?

    func loadFeed(for userId: String, audience: [String]) async {
        isLoading = true
        // In production: query Firestore for broadcasts from users this person gave status to
        // Filter to non-expired only
        try? await Task.sleep(for: .milliseconds(300))
        feed = Broadcast.mocks.filter { !$0.isExpired }
        isLoading = false
    }

    func createBroadcast(authorId: String, text: String, audience: [String]) async -> Broadcast? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = "Broadcast can't be empty."
            return nil
        }

        let broadcast = Broadcast(
            id: UUID().uuidString,
            authorId: authorId,
            text: text,
            createdAt: .now,
            expiresAt: .now.addingTimeInterval(Broadcast.lifetimeSeconds),
            reachCount: audience.count,
            statusReactions: 0
        )

        feed.insert(broadcast, at: 0)
        return broadcast
    }

    static var preview: BroadcastService {
        let service = BroadcastService()
        service.feed = Broadcast.mocks
        return service
    }
}

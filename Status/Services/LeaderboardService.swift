import Foundation

@Observable
final class LeaderboardService {
    var entries: [LeaderboardEntry] = []
    var currentScope: LeaderboardScope = .weekly
    var isLoading = false

    func loadLeaderboard(scope: LeaderboardScope) async {
        isLoading = true
        currentScope = scope
        // In production: Firestore query with server-computed scores
        try? await Task.sleep(for: .milliseconds(300))
        entries = LeaderboardEntry.mocks
        isLoading = false
    }

    func userRank(userId: String) -> LeaderboardEntry? {
        entries.first { $0.userId == userId }
    }

    static var preview: LeaderboardService {
        let service = LeaderboardService()
        service.entries = LeaderboardEntry.mocks
        return service
    }
}

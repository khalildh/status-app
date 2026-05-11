import Foundation
@preconcurrency import FirebaseFirestore

@MainActor
@Observable
final class LeaderboardService {
    var entries: [LeaderboardEntry] = []
    var currentScope: LeaderboardScope = .weekly
    var isLoading = false

    @ObservationIgnored private var _db: Firestore? = nil
    private var db: Firestore { if _db == nil { _db = Firestore.firestore() }; return _db! }

    func loadLeaderboard(scope: LeaderboardScope) async {
        isLoading = true
        currentScope = scope
        do {
            let docs = try await db.collection("users")
                .order(by: "totalStatusReceived", descending: true)
                .limit(to: 100)
                .getDocuments()

            entries = docs.documents.enumerated().compactMap { index, doc in
                do {
                    let user = try doc.data(as: User.self)
                    return LeaderboardEntry(
                        userId: user.id,
                        username: user.username,
                        displayName: user.displayName,
                        avatarURL: user.avatarURL,
                        rank: index + 1,
                        weightedScore: user.totalStatusReceived,
                        changeFromLastWeek: 0
                    )
                } catch {
                    print("[Leaderboard] Failed to decode user \(doc.documentID): \(error)")
                    return nil
                }
            }
        } catch {
            entries = []
        }
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

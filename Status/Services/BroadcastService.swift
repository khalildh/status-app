import Foundation
import FirebaseFirestore

@Observable
final class BroadcastService {
    var feed: [Broadcast] = []
    var isLoading = false
    var error: String?

    @ObservationIgnored private var _db: Firestore? = nil
    private var db: Firestore { if _db == nil { _db = Firestore.firestore() }; return _db! }
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    // MARK: - Real-time Feed

    /// Listen to broadcasts from users in the audience list (people this user gave status to).
    func startListening(authorIds: [String]) {
        listener?.remove()
        guard !authorIds.isEmpty else {
            feed = []
            return
        }

        // Firestore `in` queries support max 30 values
        let queryIds = Array(authorIds.prefix(30))
        let cutoff = Date.now.addingTimeInterval(-Broadcast.lifetimeSeconds)

        listener = db.collection("broadcasts")
            .whereField("authorId", in: queryIds)
            .whereField("createdAt", isGreaterThan: Timestamp(date: cutoff))
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    self.error = error.localizedDescription
                    return
                }
                guard let docs = snapshot?.documents else { return }
                self.feed = docs.compactMap { try? $0.data(as: Broadcast.self) }
                    .filter { !$0.isExpired }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Create Broadcast

    func createBroadcast(authorId: String, text: String, audience: [String]) async throws -> Broadcast? {
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

        try db.collection("broadcasts").document(broadcast.id).setData(from: broadcast)

        // Update user's broadcast tracking
        try await db.collection("users").document(authorId).updateData([
            "broadcastsToday": FieldValue.increment(Int64(1)),
            "lastBroadcastDate": Timestamp(date: .now)
        ])

        return broadcast
    }

    // MARK: - Preview

    static var preview: BroadcastService {
        let service = BroadcastService()
        service.feed = Broadcast.mocks
        return service
    }
}

import Foundation
import FirebaseFirestore

@Observable
final class BlockService {
    var blockedUserIds: Set<String> = []
    var isLoading = false

    @ObservationIgnored private var _db: Firestore? = nil
    private var db: Firestore { if _db == nil { _db = Firestore.firestore() }; return _db! }
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    // MARK: - Real-time Listener

    func startListening(for userId: String) {
        listener?.remove()

        listener = db.collection("blocks")
            .whereField("blockerId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                guard let docs = snapshot?.documents else { return }
                let blocks = docs.compactMap { try? $0.data(as: Block.self) }
                self.blockedUserIds = Set(blocks.map { $0.blockedUserId })
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Block / Unblock

    func blockUser(blockerId: String, blockedUserId: String, reason: BlockReason?) async throws {
        let block = Block(
            id: UUID().uuidString,
            blockerId: blockerId,
            blockedUserId: blockedUserId,
            reason: reason,
            createdAt: .now
        )
        try db.collection("blocks").document(block.id).setData(from: block)
    }

    func unblockUser(blockerId: String, blockedUserId: String) async throws {
        let docs = try await db.collection("blocks")
            .whereField("blockerId", isEqualTo: blockerId)
            .whereField("blockedUserId", isEqualTo: blockedUserId)
            .getDocuments()

        let batch = db.batch()
        for doc in docs.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }

    func isBlocked(_ userId: String) -> Bool {
        blockedUserIds.contains(userId)
    }

    // MARK: - Report (blocks + costs status)

    func reportUser(
        reporterId: String,
        reportedUserId: String,
        reason: BlockReason
    ) async throws {
        // Block the user
        try await blockUser(blockerId: reporterId, blockedUserId: reportedUserId, reason: reason)

        // Penalize the reported user's status (-10 weighted score)
        // In production this would go through a moderation queue
        try await db.collection("users").document(reportedUserId).updateData([
            "totalStatusReceived": FieldValue.increment(-10.0)
        ])
    }

    // MARK: - Preview

    static var preview: BlockService {
        let service = BlockService()
        return service
    }
}

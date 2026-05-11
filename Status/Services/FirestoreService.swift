import Foundation
@preconcurrency import FirebaseFirestore

/// Centralized Firestore access. All collection references and generic helpers live here.
/// Individual feature services call into this for reads/writes.
@Observable
final class FirestoreService {
    let db = Firestore.firestore()

    // MARK: - Collection References

    var users: CollectionReference { db.collection("users") }
    var transactions: CollectionReference { db.collection("statusTransactions") }
    var conversations: CollectionReference { db.collection("conversations") }
    var broadcasts: CollectionReference { db.collection("broadcasts") }
    var blocks: CollectionReference { db.collection("blocks") }

    func messages(for conversationId: String) -> CollectionReference {
        conversations.document(conversationId).collection("messages")
    }

    // MARK: - Generic Helpers

    /// Listen to a query as an AsyncThrowingStream of decoded documents.
    func listen<T: Decodable>(
        to query: Query,
        as type: T.Type
    ) -> AsyncThrowingStream<[T], Error> {
        AsyncThrowingStream { continuation in
            let listener = query.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: error)
                    return
                }
                guard let docs = snapshot?.documents else {
                    continuation.yield([])
                    return
                }
                do {
                    let items = try docs.map { try $0.data(as: T.self) }
                    continuation.yield(items)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    /// Listen to a single document.
    func listenToDocument<T: Decodable>(
        _ ref: DocumentReference,
        as type: T.Type
    ) -> AsyncThrowingStream<T?, Error> {
        AsyncThrowingStream { continuation in
            let listener = ref.addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: error)
                    return
                }
                guard let snapshot, snapshot.exists else {
                    continuation.yield(nil)
                    return
                }
                do {
                    let item = try snapshot.data(as: T.self)
                    continuation.yield(item)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Write Helpers

    func setDocument<T: Encodable>(_ data: T, at ref: DocumentReference) async throws {
        try ref.setData(from: data)
    }

    func addDocument<T: Encodable>(_ data: T, to collection: CollectionReference) async throws -> DocumentReference {
        try collection.addDocument(from: data)
    }
}

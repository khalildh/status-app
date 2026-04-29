import Foundation
import StoreKit
import FirebaseFirestore

@Observable
final class StoreService {
    var products: [Product] = []
    var purchasedIds: Set<String> = []
    var isLoading = false
    var error: String?

    @ObservationIgnored private var _db: Firestore?
    private var db: Firestore { if _db == nil { _db = Firestore.firestore() }; return _db! }

    @ObservationIgnored private var updateTask: Task<Void, Never>?

    static let productIds: [String] = [
        "com.status.points.5",
        "com.status.points.15",
        "com.status.points.50",
    ]

    static let pointsByProductId: [String: Int] = [
        "com.status.points.5": 5,
        "com.status.points.15": 15,
        "com.status.points.50": 50,
    ]

    init() {
        updateTask = Task { await listenForTransactions() }
    }

    deinit {
        updateTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Self.productIds)
                .sorted { $0.price < $1.price }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func purchase(_ product: Product, userId: String) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await creditPoints(userId: userId, productId: product.id)
            await transaction.finish()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    private func creditPoints(userId: String, productId: String) async {
        guard let points = Self.pointsByProductId[productId] else { return }
        try? await db.collection("users").document(userId).updateData([
            "statusBalance": FieldValue.increment(Int64(points))
        ])
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await transaction.finish()
            }
        }
    }

    static var preview: StoreService {
        StoreService()
    }
}

enum StoreError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed: "Purchase verification failed."
        }
    }
}

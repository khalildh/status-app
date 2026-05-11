import Foundation
import Testing
@testable import Status

@Suite("StoreService")
@MainActor
struct StoreServiceTests {

    // MARK: - Product IDs

    @Test("Product IDs are correctly defined")
    func productIds() {
        #expect(StoreService.productIds.count == 3)
        #expect(StoreService.productIds.contains("com.statusapp.points.5"))
        #expect(StoreService.productIds.contains("com.statusapp.points.15"))
        #expect(StoreService.productIds.contains("com.statusapp.points.50"))
    }

    // MARK: - Points Mapping

    @Test("5 points product maps to 5")
    func fivePoints() {
        #expect(StoreService.pointsByProductId["com.statusapp.points.5"] == 5)
    }

    @Test("15 points product maps to 15")
    func fifteenPoints() {
        #expect(StoreService.pointsByProductId["com.statusapp.points.15"] == 15)
    }

    @Test("50 points product maps to 50")
    func fiftyPoints() {
        #expect(StoreService.pointsByProductId["com.statusapp.points.50"] == 50)
    }

    @Test("Unknown product ID returns nil")
    func unknownProduct() {
        #expect(StoreService.pointsByProductId["com.statusapp.points.999"] == nil)
    }

    @Test("All product IDs have point mappings")
    func allMapped() {
        for id in StoreService.productIds {
            #expect(StoreService.pointsByProductId[id] != nil)
        }
    }

    // MARK: - StoreError

    @Test("StoreError has error description")
    func storeError() {
        let error = StoreError.verificationFailed
        #expect(error.errorDescription == "Purchase verification failed.")
    }

    // MARK: - StorageError

    @Test("StorageError has error description")
    func storageError() {
        let error = StorageError.invalidImage
        #expect(error.errorDescription == "Could not process the selected image.")
    }

    // MARK: - Initial State

    @Test("StoreService starts with empty products")
    func initialProducts() {
        let store = StoreService()
        #expect(store.products.isEmpty)
        #expect(store.purchasedIds.isEmpty)
        #expect(!store.isLoading)
        #expect(store.error == nil)
    }
}

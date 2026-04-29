import SwiftUI
import StoreKit

struct StoreView: View {
    @Environment(AuthService.self) private var auth
    @Environment(StoreService.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 48))
                    Text("Get More Status")
                        .font(.title2.weight(.bold))
                    Text("Buy points to give more status and grow your network.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Current balance
                if let user = auth.currentUser {
                    HStack {
                        Text("Current Balance:")
                            .foregroundStyle(.secondary)
                        Text("\(user.statusBalance) points")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                }

                // Products
                if store.isLoading {
                    ProgressView()
                    Spacer()
                } else if store.products.isEmpty {
                    VStack(spacing: 12) {
                        Text("Store unavailable")
                            .font(.headline)
                        Text("Products haven't been configured in App Store Connect yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.products, id: \.id) { product in
                            StoreProductRow(product: product) {
                                Task {
                                    guard let userId = auth.currentUser?.id else { return }
                                    try? await store.purchase(product, userId: userId)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    Spacer()
                }

                // Restore
                Button("Restore Purchases") {
                    Task { await store.restorePurchases() }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            }
            .navigationTitle("Status Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await store.loadProducts()
            }
        }
    }
}

struct StoreProductRow: View {
    let product: Product
    let onPurchase: () -> Void

    private var pointCount: Int {
        StoreService.pointsByProductId[product.id] ?? 0
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(pointCount) Status Points")
                    .font(.headline)
                Text("Give more status to unlock more connections")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onPurchase) {
                Text(product.displayPrice)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

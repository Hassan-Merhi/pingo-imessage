import PingoCore
import StoreKit
import SwiftUI

struct PingoStoreView: View {
    @ObservedObject var manager: PingoStoreManager
    let entitlements: Set<PingoEntitlementID>
    let onEntitlementsChanged: (Set<PingoEntitlementID>) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Play more. Personalize Pingo.")
                            .font(.headline)
                        Text("All purchases are one-time, family-friendly digital unlocks. No coins, loot boxes, or gambling mechanics.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Game Pack") {
                    storeRow(
                        .premiumGames,
                        title: "Premium Game Pack",
                        subtitle: premiumGameNames,
                        symbol: "🎮"
                    )
                }

                Section("Cosmetic Packs") {
                    storeRow(.neonCosmetics, title: "Neon Pack", subtitle: "Neon arena, cue and darts", symbol: "🌈")
                    storeRow(.spaceCosmetics, title: "Space Pack", subtitle: "Deep Space theme, Moon golf ball and Orbit basketball", symbol: "🌌")
                    storeRow(.classicCosmetics, title: "Gold Classics", subtitle: "Crown avatar, Gold cups and Gold cue", symbol: "👑")
                }

                Section {
                    Button {
                        Task {
                            if let restored = await manager.restorePurchases() {
                                onEntitlementsChanged(restored)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Restore Purchases")
                            Spacer()
                            if manager.isLoading { ProgressView() }
                        }
                    }
                    .disabled(manager.isLoading)

                    if let message = manager.statusMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Free Games") {
                    Text(freeGameNames)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Pingo Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await manager.loadProducts()
                let current = await manager.currentEntitlements()
                if current != entitlements { onEntitlementsChanged(current) }
            }
        }
    }

    @ViewBuilder
    private func storeRow(
        _ storeProduct: PingoStoreProduct,
        title: String,
        subtitle: String,
        symbol: String
    ) -> some View {
        let owned = entitlements.contains(storeProduct.entitlement)
        let product = manager.product(for: storeProduct)
        HStack(spacing: 12) {
            Text(symbol).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                if let product {
                    Text(product.displayPrice)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.pingoPrimary)
                } else if !owned {
                    Text("App Store product setup pending")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if owned {
                Label("Owned", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.pingoPrimary)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Owned")
            } else {
                Button("Buy") {
                    guard let product else { return }
                    Task {
                        if let updated = await manager.purchase(product) {
                            onEntitlementsChanged(updated)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
                .disabled(product == nil || manager.isLoading)
            }
        }
        .padding(.vertical, 4)
    }

    private var freeGameNames: String {
        PingoGameCatalog.launch
            .filter { PingoAccessPolicy.freeGames.contains($0.id) }
            .map(\.name)
            .joined(separator: " • ")
    }

    private var premiumGameNames: String {
        PingoGameCatalog.launch
            .filter { PingoAccessPolicy.premiumGames.contains($0.id) }
            .map(\.name)
            .joined(separator: " • ")
    }
}

import Combine
import Foundation
import PingoCore
import StoreKit

@MainActor
final class PingoStoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var statusMessage: String?

    enum StoreError: Error {
        case failedVerification
    }

    private let productIDs = Set(PingoStoreProduct.allCases.map(\.rawValue))

    func loadProducts() async {
        guard products.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: productIDs)
            products = fetched.sorted { lhs, rhs in
                rank(lhs.id) < rank(rhs.id)
            }
            statusMessage = products.isEmpty
                ? "Store products will appear after App Store Connect setup."
                : nil
        } catch {
            statusMessage = "The Pingo store is unavailable right now."
        }
    }

    func purchase(_ product: Product) async -> Set<PingoEntitlementID>? {
        isLoading = true
        defer { isLoading = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                statusMessage = "Purchase complete"
                return await currentEntitlements()
            case .pending:
                statusMessage = "Purchase pending approval"
                return nil
            case .userCancelled:
                statusMessage = nil
                return nil
            @unknown default:
                statusMessage = "The purchase could not be completed."
                return nil
            }
        } catch {
            statusMessage = "The purchase could not be verified."
            return nil
        }
    }

    func restorePurchases() async -> Set<PingoEntitlementID>? {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            statusMessage = "Purchases restored"
            return await currentEntitlements()
        } catch {
            statusMessage = "Pingo could not restore purchases."
            return nil
        }
    }

    func currentEntitlements() async -> Set<PingoEntitlementID> {
        var entitlements = Set<PingoEntitlementID>()
        for await verification in Transaction.currentEntitlements {
            guard let transaction = try? verified(verification),
                  transaction.revocationDate == nil,
                  let storeProduct = PingoStoreProduct.product(for: transaction.productID) else {
                continue
            }
            entitlements.insert(storeProduct.entitlement)
        }
        return entitlements
    }

    func product(for storeProduct: PingoStoreProduct) -> Product? {
        products.first(where: { $0.id == storeProduct.rawValue })
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw StoreError.failedVerification
        }
    }

    private func rank(_ identifier: String) -> Int {
        PingoStoreProduct.allCases.firstIndex(where: { $0.rawValue == identifier }) ?? Int.max
    }
}

import Foundation
import StoreKit
import Combine

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isPro: Bool = false
    @Published var monthlyProduct: Product?
    @Published var yearlyProduct: Product?
    @Published var isLoading = false
    @Published var loadError: String?

    static let monthlyID = "com.zzoutuo.PRDay.pro.monthly"
    static let yearlyID = "com.zzoutuo.PRDay.pro.yearly"

    private var transactionListener: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await checkPurchased() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            let products = try await Product.products(for: [Self.monthlyID, Self.yearlyID])
            monthlyProduct = products.first { $0.id == Self.monthlyID }
            yearlyProduct = products.first { $0.id == Self.yearlyID }
            loadError = products.isEmpty ? "Purchase options unavailable. Try again later." : nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await checkPurchased()
                    return true
                case .unverified:
                    loadError = "Purchase could not be verified."
                    return false
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPurchased()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func checkPurchased() async {
        var pro = false
        for id in [Self.monthlyID, Self.yearlyID] {
            if let result = await Transaction.currentEntitlement(for: id),
               case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                pro = true
            }
        }
        isPro = pro
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.checkPurchased()
                    }
                }
            }
        }
    }
}

import Foundation
import StoreKit

@MainActor
public final class StoreKitFlowStore: ObservableObject {
    @Published public private(set) var products: [StoreProduct] = []
    @Published public private(set) var purchasedProductIDs: Set<String> = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var isPurchasing = false
    @Published public private(set) var purchaseError: Error? = nil

    private let productService: any ProductFetchable
    private let purchaseService: any Purchasable
    private let entitlementService: any EntitlementCheckable
    private let transactionService: any TransactionObservable

    public var productIDs: [String] = []

    public init(
        productService: any ProductFetchable,
        purchaseService: any Purchasable = PurchaseService(),
        entitlementService: any EntitlementCheckable,
        transactionService: any TransactionObservable
    ) {
        self.productService = productService
        self.purchaseService = purchaseService
        self.entitlementService = entitlementService
        self.transactionService = transactionService
    }

    public func initialize() async {
        isLoading = true
        defer { isLoading = false }
        async let fetchedProducts = productService.fetchProducts(ids: productIDs)
        async let entitlements = entitlementService.currentEntitlements()
        do {
            products = try await fetchedProducts
        } catch {
            print("[StoreKitFlowStore] Fetch error: \(error)")
        }
        purchasedProductIDs = await entitlements
        listenForTransactions()
    }

    public func purchase(_ product: StoreProduct) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        do {
            let result = try await purchaseService.purchase(product: product)
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return }
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error
        }
    }

    public func isPurchased(_ product: StoreProduct) -> Bool {
        purchasedProductIDs.contains(product.id)
    }

    private func listenForTransactions() {
        Task(priority: .background) {
            for await result in transactionService.updates() {
                guard case .verified(let transaction) = result else { continue }
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
            }
        }
    }
}

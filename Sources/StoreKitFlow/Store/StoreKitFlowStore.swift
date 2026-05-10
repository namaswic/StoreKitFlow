import Foundation

@MainActor
public final class StoreKitFlowStore: ObservableObject {
    @Published public private(set) var products: [StoreProduct] = []
    @Published public private(set) var purchasedProductIDs: Set<String> = []
    @Published public private(set) var isLoading = false

    private let productService: any ProductFetchable
    private let entitlementService: any EntitlementCheckable
    private let transactionService: any TransactionObservable

    public var productIDs: [String] = []

    public init(
        productService: any ProductFetchable,
        entitlementService: any EntitlementCheckable,
        transactionService: any TransactionObservable
    ) {
        self.productService = productService
        self.entitlementService = entitlementService
        self.transactionService = transactionService
    }

    public func initialize() async {
        isLoading = true
        defer { isLoading = false }
        print("[StoreKitFlowStore] Fetching product IDs: \(productIDs)")
        async let fetchedProducts = productService.fetchProducts(ids: productIDs)
        async let entitlements = entitlementService.currentEntitlements()
        do {
            let fetched = try await fetchedProducts
            print("[StoreKitFlowStore] Fetched \(fetched.count) products: \(fetched.map(\.id))")
            products = fetched
        } catch {
            print("[StoreKitFlowStore] Fetch error: \(error)")
        }
        purchasedProductIDs = await entitlements
        listenForTransactions()
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

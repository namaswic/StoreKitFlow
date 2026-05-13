import Foundation
import StoreKit

@MainActor
public final class StoreKitFlowStore: ObservableObject {
    @Published public private(set) var products: [StoreProduct] = []
    @Published public private(set) var purchasedProductIDs: Set<String> = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var isPurchasing = false
    @Published public private(set) var purchaseError: Error? = nil
    @Published public private(set) var logs: [StoreLog] = []

    private let productService: any ProductFetchable
    private let purchaseService: any Purchasable
    private let entitlementService: any EntitlementCheckable
    private let transactionService: any TransactionObservable

    public var productIDs: [String] = []
    public private(set) var configuration: StoreKitFlowConfiguration

    public init(
        productService: any ProductFetchable,
        purchaseService: any Purchasable = PurchaseService(),
        entitlementService: any EntitlementCheckable,
        transactionService: any TransactionObservable,
        configuration: StoreKitFlowConfiguration = .init(productIDs: [])
    ) {
        self.productService = productService
        self.purchaseService = purchaseService
        self.entitlementService = entitlementService
        self.transactionService = transactionService
        self.configuration = configuration
        self.productIDs = configuration.productIDs
    }

    public func initialize() async {
        isLoading = true
        defer { isLoading = false }

        log(.fetchStarted(ids: productIDs))
        async let fetchedProducts = productService.fetchProducts(ids: productIDs)
        async let entitlements = entitlementService.currentEntitlements()

        do {
            products = try await fetchedProducts
            log(.fetchCompleted(count: products.count))
        } catch {
            log(.fetchFailed(error: error.localizedDescription))
        }

        let currentEntitlements = await entitlements
        purchasedProductIDs = currentEntitlements
        log(.entitlementsLoaded(productIDs: currentEntitlements))

        await processUnfinishedTransactions()
        listenForTransactions()
    }

    public func purchase(_ product: StoreProduct) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        log(.purchaseStarted(productID: product.id))

        do {
            let result = try await purchaseService.purchase(product: product)
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    log(.transactionUnverified(productID: product.id))
                    return
                }
                log(
                    .transactionVerified(
                        productID: transaction.productID,
                        transactionID: transaction.id,
                        originalTransactionID: transaction.originalID
                    )
                )
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                log(
                    .transactionFinished(
                        productID: transaction.productID,
                        transactionID: transaction.id,
                        originalTransactionID: transaction.originalID
                    )
                )
                log(.purchaseSucceeded(productID: product.id))
            case .userCancelled:
                log(.purchaseCancelled(productID: product.id))
            case .pending:
                log(.purchasePending(productID: product.id))
            @unknown default:
                break
            }
        } catch {
            purchaseError = error
            log(.purchaseFailed(productID: product.id, error: error.localizedDescription))
        }
    }

    public func isPurchased(_ product: StoreProduct) -> Bool {
        purchasedProductIDs.contains(product.id)
    }

    public func clearLogs() {
        logs.removeAll()
    }

    private func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            switch result {
                case .verified(let transaction):
                    log(
                        .unfinishedTransactionFound(
                            productID: transaction.productID,
                            transactionID: transaction.id,
                            originalTransactionID: transaction.originalID
                        )
                    )
                    purchasedProductIDs.insert(transaction.productID)
                    await transaction.finish()
                    log(
                        .transactionFinished(
                            productID: transaction.productID,
                            transactionID: transaction.id,
                            originalTransactionID: transaction.originalID
                        )
                    )
                case .unverified(let transaction, _):
                    log(
                        .transactionUnverified(
                            productID: transaction.productID
                        )
                    )
            }
        }
    }

    private func listenForTransactions() {
        Task(priority: .background) {
            for await result in transactionService.updates() {
                switch result {
                case .verified(let transaction):
                    await MainActor.run {
                        self.log(
                            .transactionReceived(
                                productID: transaction.productID,
                                transactionID: transaction.id,
                                originalTransactionID: transaction.originalID
                            )
                        )
                        self.log(
                            .transactionVerified(
                                productID: transaction.productID,
                                transactionID: transaction.id,
                                originalTransactionID: transaction.originalID
                            )
                        )
                        self.purchasedProductIDs.insert(transaction.productID)
                    }
                    await transaction.finish()
                    await MainActor.run {
                        self.log(
                            .transactionFinished(
                                productID: transaction.productID,
                                transactionID: transaction.id,
                                originalTransactionID: transaction.originalID
                            )
                        )
                    }
                case .unverified(let transaction, _):
                    await MainActor.run {
                        self.log(.transactionUnverified(productID: transaction.productID))
                    }
                }
            }
        }
    }

    private func log(_ event: StoreLogEvent) {
        logs.insert(StoreLog(event: event), at: 0)
        StoreKitFlowLogger.shared.log(event)
    }
}

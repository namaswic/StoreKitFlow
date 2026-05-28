import Foundation
import StoreKit

@MainActor
public final class StoreKitFlowStore: ObservableObject, StoreObservable {

    // MARK: - Published state

    @Published public private(set) var products: [StoreProduct] = []
    @Published public private(set) var purchasedProductIDs: Set<String> = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var isPurchasing = false
    @Published public private(set) var logs: [StoreLog] = []
    /// Persistent history of every verified transaction seen by this store, ordered oldest first.
    /// Populated from `TransactionCache` on `initialize()` and updated after every `finish()`.
    @Published public private(set) var transactionHistory: [CachedTransaction] = []

    // MARK: - Callbacks

    /// Called once per verified external transaction (renewal, revocation, family sharing).
    ///
    /// Set this before calling `initialize()`. It fires after `finish()` has been called,
    /// so it is safe to use for analytics or server-side receipt validation.
    ///
    /// - Note: For auto-renewable subscriptions, do **not** treat this callback as a definitive
    ///   entitlement grant. StoreKit can deliver the same transaction ID multiple times before
    ///   `finish()` completes. Check `Product.SubscriptionInfo.Status` in your handler to determine
    ///   actual access. See https://developer.apple.com/forums/thread/877090022
    public var onTransactionUpdate: (@Sendable (TransactionUpdate) async -> Void)?

    // MARK: - Dependencies

    private let productService: any ProductFetchable
    private let purchaseService: any Purchasable
    private let entitlementService: any EntitlementCheckable
    private let transactionService: any TransactionObservable
    private let cache: any TransactionCaching
    private let logger: any StoreKitFlowLogging

    // MARK: - SRP sub-components

    private let listener = TransactionListener()
    private lazy var orchestrator = TransactionOrchestrator(
        cache: cache,
        logger: logger,
        cacheEnabled: configuration.enableTransactionCache
    )

    // MARK: - Configuration

    public var productIDs: [String] = []
    public private(set) var configuration: StoreKitFlowConfiguration

    // MARK: - Init

    public init(
        productService: any ProductFetchable,
        purchaseService: any Purchasable = PurchaseService(),
        entitlementService: any EntitlementCheckable,
        transactionService: any TransactionObservable,
        cache: (any TransactionCaching)? = nil,
        logger: (any StoreKitFlowLogging)? = nil,
        configuration: StoreKitFlowConfiguration = .init(productIDs: [])
    ) {
        self.productService = productService
        self.purchaseService = purchaseService
        self.entitlementService = entitlementService
        self.transactionService = transactionService
        self.cache = cache ?? TransactionCache.shared
        self.logger = logger ?? StoreKitFlowLogger.shared
        self.configuration = configuration
        self.productIDs = configuration.productIDs
    }

    // MARK: - Initialize

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

        if configuration.enableTransactionCache {
            let unfinishedIDs = await orchestrator.processUnfinished()
            unfinishedIDs.forEach { purchasedProductIDs.insert($0) }

            let reconciledIDs = await orchestrator.reconcile()
            reconciledIDs.forEach { purchasedProductIDs.insert($0) }

            transactionHistory = cache.all()
        }

        startListening()
    }

    // MARK: - Purchase

    /// Initiates a purchase for the given product and returns a typed outcome.
    ///
    /// The result is `@discardableResult` — you can `switch` on it for full control,
    /// or ignore it if you only need to observe `purchasedProductIDs`.
    ///
    /// ```swift
    /// switch await store.purchase(product) {
    /// case .success(let productID, _, _, _):
    ///     print("Purchased \(productID)")
    /// case .pending:
    ///     showPendingUI()
    /// case .cancelled:
    ///     break
    /// case .unverified:
    ///     // Transaction failed StoreKit's local verification — treat as not purchased
    ///     break
    /// case .failed(let error):
    ///     showError(error)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - product: The product to purchase.
    ///   - attributes: Optional purchase metadata such as `appAccountToken` or `quantity`.
    ///                 Defaults to an empty `PurchaseAttributes()`.
    ///   - shouldProcessUnfinishedTransactions: When `true`, any unfinished transactions from previous sessions are
    ///                       finished before the new purchase begins. This is particularly important
    ///                       for re-subscribing after an expired subscription — StoreKit can silently
    ///                       return `.success` without prompting the user if unfinished transactions
    ///                       are still in the queue. See https://stackoverflow.com/q/77355821 for details.
    ///                       Defaults to `false`
    /// - Returns: A `PurchaseOutcome` describing what happened.
    @discardableResult
    public func purchase(
        _ product: StoreProduct,
        attributes: PurchaseAttributes = PurchaseAttributes(),
        shouldProcessUnfinishedTransactions: Bool = false
    ) async -> PurchaseOutcome {
        isPurchasing = true
        defer { isPurchasing = false }

        log(.purchaseStarted(productID: product.id))

        if shouldProcessUnfinishedTransactions {
            let ids = await orchestrator.processUnfinished()
            ids.forEach { purchasedProductIDs.insert($0) }
        }

        do {
            let result = try await purchaseService.purchase(product: product, attributes: attributes)
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    log(.transactionUnverified(productID: product.id))
                    return .unverified
                }
                log(.transactionVerified(
                    productID: transaction.productID,
                    transactionID: transaction.id,
                    originalTransactionID: transaction.originalID
                ))
                purchasedProductIDs.insert(transaction.productID)
                await orchestrator.finishAndCache(transaction, source: .purchase, path: .storePurchase)
                if configuration.enableTransactionCache { transactionHistory = cache.all() }
                log(.purchaseSucceeded(productID: product.id))
                return .success(
                    productID: transaction.productID,
                    transactionID: transaction.id,
                    originalTransactionID: transaction.originalID,
                    appAccountToken: transaction.appAccountToken
                )
            case .userCancelled:
                log(.purchaseCancelled(productID: product.id))
                return .cancelled
            case .pending:
                // Transaction is deferred — do NOT grant access yet. Common causes:
                // Ask to Buy awaiting parental approval, Family Sharing organizer approval,
                // billing issue (expired card, insufficient funds), or bank authorization delay.
                // Listen via Transaction.updates — it will deliver the final result when resolved.
                // See https://www.reddit.com/r/iOSProgramming/comments/1jbvatg/pending_transactions_storekit2/
                log(.purchasePending(productID: product.id))
                return .pending
            @unknown default:
                return .cancelled
            }
        } catch {
            log(.purchaseFailed(productID: product.id, error: error.localizedDescription))
            return .failed(.purchaseFailed(error))
        }
    }

    public func isPurchased(_ product: StoreProduct) -> Bool {
        purchasedProductIDs.contains(product.id)
    }

    // MARK: - Restore

    /// Restores purchases for the current user and syncs entitlements.
    ///
    /// StoreKit 2 has no dedicated "restore purchases" sheet. Instead, this method:
    /// 1. Calls `AppStore.sync()` to refresh the App Store receipt and trigger re-delivery
    ///    of any transactions the device hasn't seen (e.g. after reinstall or new device).
    /// 2. Re-reads `currentEntitlements` to rebuild `purchasedProductIDs` from the ground up.
    ///
    /// When to call this:
    /// - In response to a "Restore Purchases" button (required by App Store Review guidelines
    ///   for apps with non-consumable or auto-renewable products).
    /// - After a reinstall where the user has lost access to previously purchased content.
    ///
    /// - Note: `AppStore.sync()` may present an App Store sign-in sheet. Call this only in
    ///   response to an explicit user action — never call it automatically on launch.
    ///   See https://developer.apple.com/documentation/storekit/appstore/sync()
    public func restorePurchases() async {
        log(.restoreStarted)
        do {
            try await AppStore.sync()
            let entitlements = await entitlementService.currentEntitlements()
            purchasedProductIDs = entitlements
            log(.restoreCompleted(productIDs: entitlements))
        } catch {
            log(.restoreFailed(error: error.localizedDescription))
        }
    }

    // MARK: - Cache & Logs

    public func clearLogs() {
        logs.removeAll()
    }

    public func clearTransactionHistory() {
        guard configuration.enableTransactionCache else { return }
        cache.clearAll()
        transactionHistory = []
    }

    /// Cross-references `Transaction.currentEntitlements` against the cache to surface
    /// renewals that were delivered by StoreKit but never processed by this app.
    /// Call this after a purchase completes via a StoreKit view (ProductView, SubscriptionStoreView)
    /// to ensure the transaction is recorded even if it was finished before the updates listener saw it.
    public func reconcile() async {
        guard configuration.enableTransactionCache else { return }
        let ids = await orchestrator.reconcile()
        ids.forEach { purchasedProductIDs.insert($0) }
        transactionHistory = cache.all()
    }

    // MARK: - Private

    private func startListening() {
        listener.start(
            service: transactionService,
            onVerified: { [weak self] transaction in
                guard let self else { return }
                self.log(.transactionReceived(
                    productID: transaction.productID,
                    transactionID: transaction.id,
                    originalTransactionID: transaction.originalID
                ))
                self.log(.transactionVerified(
                    productID: transaction.productID,
                    transactionID: transaction.id,
                    originalTransactionID: transaction.originalID
                ))
                // Only grant entitlement for non-subscription products.
                // For auto-renewable subscriptions, entitlement must be derived from
                // SubscriptionInfo.Status — not from the transaction update directly.
                if transaction.productType != .autoRenewable {
                    self.purchasedProductIDs.insert(transaction.productID)
                }
                await self.orchestrator.finishAndCache(transaction, source: .renewal, path: .transactionUpdates)
                if self.configuration.enableTransactionCache {
                    self.transactionHistory = self.cache.all()
                }
                if let handler = self.onTransactionUpdate {
                    let reason: TransactionUpdate.Reason
                    if transaction.revocationDate != nil {
                        reason = .revocation
                    } else if transaction.ownershipType == .familyShared {
                        reason = .familySharing
                    } else {
                        reason = .renewal
                    }
                    await handler(TransactionUpdate(
                        productID: transaction.productID,
                        transactionID: transaction.id,
                        reason: reason
                    ))
                }
            },
            onUnverified: { [weak self] productID in
                self?.log(.transactionUnverified(productID: productID))
            }
        )
    }

    private func log(_ event: StoreLogEvent) {
        logs.insert(StoreLog(event: event), at: 0)
        logger.log(event)
    }
}

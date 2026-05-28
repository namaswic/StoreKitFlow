import Foundation
import StoreKit

@MainActor
public final class StoreKitFlowStore: ObservableObject {
    @Published public private(set) var products: [StoreProduct] = []
    @Published public private(set) var purchasedProductIDs: Set<String> = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var isPurchasing = false
    @Published public private(set) var logs: [StoreLog] = []
    /// Persistent history of every verified transaction seen by this store, ordered oldest first.
    /// Populated from `TransactionCache` on `initialize()` and updated after every `finish()`.
    @Published public private(set) var transactionHistory: [CachedTransaction] = []

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

    /// Tracks transaction IDs already processed in `listenForTransactionsUpdates` to prevent
    /// duplicate handling caused by StoreKit re-delivering the same transaction before finish() completes.
    private var seenTransactionIDs: Set<UInt64> = []

    /// Holds the transaction update listener task alive for the lifetime of the store.
    /// Must be stored — a discarded Task handle is eligible for cancellation, which would
    /// silently stop renewals from arriving after the first purchase.
    private var transactionListenerTask: Task<Void, Never>?

    private let cache = TransactionCache.shared


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

        if configuration.enableTransactionCache {
            await processUnfinishedTransactions()
            await runReconciliation()
            transactionHistory = cache.all()
        }
        listenForTransactionsUpdates()
    }

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
            await processUnfinishedTransactions()
        }
        
        do {
            let result = try await purchaseService.purchase(product: product, attributes: attributes)
            switch result {
            case .success(let verification):
                // StoreKit returns a verified or unverified transaction — always check before granting access
                guard case .verified(let transaction) = verification else {
                    log(.transactionUnverified(productID: product.id))
                    return .unverified
                }
                log(
                    .transactionVerified(
                        productID: transaction.productID,
                        transactionID: transaction.id,
                        originalTransactionID: transaction.originalID
                    )
                )
                purchasedProductIDs.insert(transaction.productID)
                await finishAndCache(transaction, source: .purchase, path: .storePurchase)
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
            return .failed(error)
        }
    }

    public func isPurchased(_ product: StoreProduct) -> Bool {
        purchasedProductIDs.contains(product.id)
    }

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

    public func clearLogs() {
        logs.removeAll()
    }

    public func clearTransactionHistory() {
        guard configuration.enableTransactionCache else { return }
        cache.clearAll()
        transactionHistory = []
    }

    /// Drains StoreKit's unfinished transaction queue by verifying and finishing each pending transaction.
    ///
    /// Unfinished transactions accumulate when a previous app session granted entitlement but crashed
    /// or was killed before calling `transaction.finish()`. StoreKit re-delivers these on every launch
    /// until they are explicitly finished.
    ///
    /// Leaving them in the queue can cause silent `.success` responses when re-purchasing an expired
    /// subscription — StoreKit resolves the unfinished transaction instead of initiating a new purchase,
    /// and the user never sees a confirmation sheet. The root cause (confirmed in both sandbox and
    /// production) is unfinished renewal transactions blocking the new purchase flow — StoreKit
    /// resolves the stale transaction instead of initiating a fresh one.
    /// See https://stackoverflow.com/q/77355821 and https://developer.apple.com/forums/thread/723126
    ///
    /// - Verified transactions: entitlement is granted and the transaction is finished.
    /// - Unverified transactions: logged and skipped — do not grant access for transactions that fail
    ///   StoreKit's local cryptographic check.
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
                    await finishAndCache(transaction, source: .unfinished, path: .transactionUnfinished)
                case .unverified(let transaction, _):
                    log(
                        .transactionUnverified(
                            productID: transaction.productID
                        )
                    )
            }
        }
    }

    /// Listens for external transaction updates (renewals, revocations, family sharing, Ask to Buy approvals).
    ///
    /// **Subscription handling:** Per Apple DTS and the SKDemo sample, `Transaction.updates` for
    /// auto-renewable subscriptions should **only** call `finish()`. Do not grant entitlement here —
    /// subscription access must be checked via `Product.SubscriptionInfo.Status`. Inserting directly
    /// into `purchasedProductIDs` from this loop causes duplicate state updates because StoreKit
    /// can re-deliver the same transaction 2–3 times before `finish()` completes.
    /// See https://developer.apple.com/forums/thread/877090022
    ///
    /// **Non-consumables / non-renewing subscriptions:** Entitlement is inserted into
    /// `purchasedProductIDs` as usual since they have no renewal lifecycle.
    ///
    /// **Deduplication:** `seenTransactionIDs` guards against the same transaction being processed
    /// more than once within the lifetime of this listener.
    private func listenForTransactionsUpdates() {
        transactionListenerTask = Task(priority: .background) {
            for await result in transactionService.updates() {
                switch result {
                case .verified(let transaction):
                    // Deduplicate — StoreKit can re-deliver the same ID before finish() completes
                    guard !seenTransactionIDs.contains(transaction.id) else { continue }
                    seenTransactionIDs.insert(transaction.id)

                    log(
                        .transactionReceived(
                            productID: transaction.productID,
                            transactionID: transaction.id,
                            originalTransactionID: transaction.originalID
                        )
                    )
                    log(
                        .transactionVerified(
                            productID: transaction.productID,
                            transactionID: transaction.id,
                            originalTransactionID: transaction.originalID
                        )
                    )

                    // Only grant entitlement for non-subscription products.
                    // For auto-renewable subscriptions, entitlement must be derived from
                    // SubscriptionInfo.Status — not from the transaction update directly.
                    if transaction.productType != .autoRenewable {
                        purchasedProductIDs.insert(transaction.productID)
                    }

                    await finishAndCache(transaction, source: .renewal, path: .transactionUpdates)

                    if let handler = onTransactionUpdate {
                        let reason: TransactionUpdate.Reason
                        if transaction.revocationDate != nil {
                            reason = .revocation
                        } else if transaction.ownershipType == .familyShared {
                            reason = .familySharing
                        } else {
                            reason = .renewal
                        }
                        await handler(
                            TransactionUpdate(
                                productID: transaction.productID,
                                transactionID: transaction.id,
                                reason: reason
                            )
                        )
                    }
                case .unverified(let transaction, _):
                    log(.transactionUnverified(productID: transaction.productID))
                }
            }
        }
    }

    /// Finishes a verified transaction, records it in the cache, and logs both events.
    private func finishAndCache(_ transaction: Transaction, source: CacheSource, path: TransactionDeliveryPath) async {
        let finishedAt = Date()
        await transaction.finish()
        log(
            .transactionFinished(
                productID: transaction.productID,
                transactionID: transaction.id,
                originalTransactionID: transaction.originalID,
                reason: finishReason(for: transaction)
            )
        )
        let productType = ProductType(transaction.productType)
        let entry = CachedTransaction(
            transaction: transaction,
            productType: productType,
            finishedAt: finishedAt,
            source: source,
            path: path
        )
        if configuration.enableTransactionCache {
            cache.record(entry)
            transactionHistory = cache.all()
            log(.transactionCached(productID: transaction.productID, transactionID: transaction.id, source: source))
        }
    }

    /// Cross-references `Transaction.currentEntitlements` against the cache to surface
    /// renewals that were delivered by StoreKit but never processed by this app.
    /// Manually triggers a reconciliation pass. Call this after a purchase completes via
    /// a StoreKit view (ProductView, SubscriptionStoreView) to ensure the transaction
    /// is recorded in the cache even if it was finished before the updates listener saw it.
    public func reconcile() async {
        guard configuration.enableTransactionCache else { return }
        await runReconciliation()
        transactionHistory = cache.all()
    }

    private func runReconciliation() async {
        let missing = await cache.reconcile()
        if missing.isEmpty {
            log(.reconciliationComplete)
            return
        }
        log(.reconciliationFound(count: missing.count))
        for transaction in missing {
            purchasedProductIDs.insert(transaction.productID)
            await finishAndCache(transaction, source: .renewal, path: .reconciliation)
        }
    }

    private func log(_ event: StoreLogEvent) {
        logs.insert(StoreLog(event: event), at: 0)
        StoreKitFlowLogger.shared.log(event)
    }
}

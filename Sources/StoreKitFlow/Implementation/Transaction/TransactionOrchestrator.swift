import StoreKit

/// Owns `finish()`-and-cache logic, unfinished transaction draining, and reconciliation.
/// Extracted from `StoreKitFlowStore` to satisfy SRP — returns results back to the store
/// which retains ownership of `@Published` state.
@MainActor
final class TransactionOrchestrator {
    private let cache: any TransactionCaching
    private let logger: any StoreKitFlowLogging
    private let cacheEnabled: Bool

    init(cache: any TransactionCaching, logger: any StoreKitFlowLogging, cacheEnabled: Bool) {
        self.cache = cache
        self.logger = logger
        self.cacheEnabled = cacheEnabled
    }

    // MARK: - finish + cache

    /// Finishes a transaction, records it in the cache, and returns the finish timestamp.
    @discardableResult
    func finishAndCache(
        _ transaction: Transaction,
        source: CacheSource,
        path: TransactionDeliveryPath
    ) async -> Date {
        let finishedAt = Date()
        await transaction.finish()
        logger.log(
            .transactionFinished(
                productID: transaction.productID,
                transactionID: transaction.id,
                originalTransactionID: transaction.originalID,
                reason: finishReason(for: transaction)
            )
        )
        if cacheEnabled {
            let productType = ProductType(transaction.productType)
            let entry = CachedTransaction(
                transaction: transaction,
                productType: productType,
                finishedAt: finishedAt,
                source: source,
                path: path
            )
            cache.record(entry)
            logger.log(.transactionCached(
                productID: transaction.productID,
                transactionID: transaction.id,
                source: source
            ))
        }
        return finishedAt
    }

    // MARK: - Unfinished drain

    /// Drains `Transaction.unfinished` and returns product IDs that should be granted entitlement.
    func processUnfinished() async -> [String] {
        var grantedProductIDs: [String] = []
        for await result in Transaction.unfinished {
            switch result {
            case .verified(let transaction):
                logger.log(.unfinishedTransactionFound(
                    productID: transaction.productID,
                    transactionID: transaction.id,
                    originalTransactionID: transaction.originalID
                ))
                grantedProductIDs.append(transaction.productID)
                await finishAndCache(transaction, source: .unfinished, path: .transactionUnfinished)
            case .unverified(let transaction, _):
                logger.log(.transactionUnverified(productID: transaction.productID))
            }
        }
        return grantedProductIDs
    }

    // MARK: - Reconciliation

    /// Reconciles `Transaction.currentEntitlements` against the cache and finishes any missed transactions.
    /// Returns product IDs that should be granted entitlement from missed renewals.
    func reconcile() async -> [String] {
        let missing = await cache.reconcile()
        if missing.isEmpty {
            logger.log(.reconciliationComplete)
            return []
        }
        logger.log(.reconciliationFound(count: missing.count))
        var grantedProductIDs: [String] = []
        for transaction in missing {
            grantedProductIDs.append(transaction.productID)
            await finishAndCache(transaction, source: .renewal, path: .reconciliation)
        }
        return grantedProductIDs
    }
}

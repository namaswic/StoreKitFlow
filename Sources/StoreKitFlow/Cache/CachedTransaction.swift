import Foundation
import StoreKit

/// A persistent record of a single transaction seen by StoreKitFlow.
///
/// Stored in `TransactionCache` as a JSON array in Application Support.
/// Every verified transaction is recorded regardless of product type —
/// this gives you a complete audit trail across app sessions.
public struct CachedTransaction: Codable, Identifiable, Sendable {
    /// StoreKit transaction ID — unique per transaction event.
    public let id: UInt64
    /// Original transaction ID — shared across all renewals of the same subscription.
    public let originalID: UInt64
    public let productID: String
    public let productType: ProductType
    public let purchaseDate: Date
    /// Non-nil for auto-renewable and non-renewing subscriptions.
    public let expirationDate: Date?
    /// Non-nil if Apple revoked the transaction (e.g. refund granted).
    public let revocationDate: Date?
    public let appAccountToken: UUID?
    /// "Production" or "Sandbox".
    public let environment: String
    /// When `transaction.finish()` was called. `nil` if not yet finished (e.g. FinishPolicy held it back).
    public let finishedAt: Date?
    /// How this transaction entered the cache.
    public let source: CacheSource

    public init(
        id: UInt64,
        originalID: UInt64,
        productID: String,
        productType: ProductType,
        purchaseDate: Date,
        expirationDate: Date?,
        revocationDate: Date?,
        appAccountToken: UUID?,
        environment: String,
        finishedAt: Date?,
        source: CacheSource
    ) {
        self.id = id
        self.originalID = originalID
        self.productID = productID
        self.productType = productType
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
        self.appAccountToken = appAccountToken
        self.environment = environment
        self.finishedAt = finishedAt
        self.source = source
    }
}

/// How a transaction entered the cache.
public enum CacheSource: String, Codable, Sendable, CaseIterable {
    /// Came from a direct `purchase()` call in the app.
    case purchase
    /// Came from `Transaction.updates` — an external renewal, revocation, or family sharing event.
    case renewal
    /// Came from `restorePurchases()` → `AppStore.sync()`.
    case restore
    /// Came from `Transaction.unfinished` during app launch drain.
    case unfinished
}

extension CachedTransaction {
    /// Convenience init from a StoreKit `Transaction` and a source.
    init(transaction: Transaction, productType: ProductType, finishedAt: Date?, source: CacheSource) {
        self.init(
            id: transaction.id,
            originalID: transaction.originalID,
            productID: transaction.productID,
            productType: productType,
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate,
            revocationDate: transaction.revocationDate,
            appAccountToken: transaction.appAccountToken,
            environment: transaction.environment.rawValue,
            finishedAt: finishedAt,
            source: source
        )
    }
}

import Foundation

public enum PurchaseOutcome: Sendable {
    case success(
        productID: String,
        transactionID: UInt64,
        originalTransactionID: UInt64,
        appAccountToken: UUID?
    )
    case pending
    case cancelled
    case unverified
    case failed(StoreKitFlowError)
}

/// A typed error produced by StoreKitFlow purchase operations.
public enum StoreKitFlowError: Error, Sendable {
    /// The product could not be found in the App Store.
    case productNotFound
    /// The purchase call threw an error from StoreKit or the payment system.
    case purchaseFailed(Error)
    /// An unexpected error that doesn't fit a more specific category.
    case unknown(Error)
}

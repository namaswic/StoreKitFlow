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
    case failed(Error)
}

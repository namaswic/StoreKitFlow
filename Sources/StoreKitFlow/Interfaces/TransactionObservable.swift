import StoreKit

public protocol TransactionObservable: Sendable {
    func updates() -> AsyncStream<VerificationResult<Transaction>>
}

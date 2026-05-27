import Combine
import StoreKit

public protocol TransactionObservable: Sendable {
    func updates() -> AsyncStream<VerificationResult<Transaction>>
    func updatesPublisher() -> AnyPublisher<VerificationResult<Transaction>, Never>
}

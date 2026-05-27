import Combine
import StoreKit

public final class MockTransactionService: TransactionObservable {
    public init() {}

    public func updates() -> AsyncStream<VerificationResult<Transaction>> {
        AsyncStream { _ in }
    }

    public func updatesPublisher() -> AnyPublisher<VerificationResult<Transaction>, Never> {
        Empty().eraseToAnyPublisher()
    }
}

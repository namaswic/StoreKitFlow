import Combine
import StoreKit

public final class TransactionService: TransactionObservable {
    public init() {}

    public func updates() -> AsyncStream<VerificationResult<Transaction>> {
        AsyncStream { continuation in
            let task = Task(priority: .background) {
                for await result in Transaction.updates {
                    continuation.yield(result)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func updatesPublisher() -> AnyPublisher<VerificationResult<Transaction>, Never> {
        let subject = PassthroughSubject<VerificationResult<Transaction>, Never>()
        let task = Task(priority: .background) {
            for await result in Transaction.updates {
                subject.send(result)
            }
            subject.send(completion: .finished)
        }
        return subject
            .handleEvents(receiveCancel: { task.cancel() })
            .eraseToAnyPublisher()
    }
}

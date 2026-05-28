import Combine
import StoreKit

public protocol TransactionObservable: Sendable {
    func updates() -> AsyncStream<VerificationResult<Transaction>>
}

public extension TransactionObservable {
    func updatesPublisher() -> AnyPublisher<VerificationResult<Transaction>, Never> {
        let subject = PassthroughSubject<VerificationResult<Transaction>, Never>()
        let task = Task(priority: .background) {
            for await result in self.updates() {
                subject.send(result)
            }
            subject.send(completion: .finished)
        }
        return subject
            .handleEvents(receiveCancel: { task.cancel() })
            .eraseToAnyPublisher()
    }
}

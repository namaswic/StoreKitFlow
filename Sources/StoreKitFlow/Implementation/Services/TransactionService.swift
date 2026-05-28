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
}

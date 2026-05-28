import StoreKit

/// Owns the long-lived task that drains `Transaction.updates` and deduplicates deliveries.
/// Extracted from `StoreKitFlowStore` to satisfy SRP — the store delegates stream management here.
@MainActor
final class TransactionListener {
    private var task: Task<Void, Never>?
    private var seenIDs: Set<UInt64> = []

    func start(
        service: any TransactionObservable,
        onVerified: @escaping @MainActor (Transaction) async -> Void,
        onUnverified: @escaping @MainActor (String) -> Void
    ) {
        task = Task(priority: .background) { [weak self] in
            for await result in service.updates() {
                guard let self else { return }
                switch result {
                case .verified(let transaction):
                    guard !self.seenIDs.contains(transaction.id) else { continue }
                    self.seenIDs.insert(transaction.id)
                    await onVerified(transaction)
                case .unverified(let transaction, _):
                    await onUnverified(transaction.productID)
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}

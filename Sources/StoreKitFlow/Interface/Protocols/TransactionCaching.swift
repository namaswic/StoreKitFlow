import StoreKit

@MainActor
public protocol TransactionCaching: AnyObject {
    func all() -> [CachedTransaction]
    func record(_ entry: CachedTransaction)
    func reconcile() async -> [Transaction]
    func clearAll()
}

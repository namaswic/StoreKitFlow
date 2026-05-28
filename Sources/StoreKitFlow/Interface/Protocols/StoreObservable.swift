import Foundation

/// The full public interface of a StoreKitFlow store.
///
/// `StoreKitFlowStore` conforms to this protocol. Use it to type-check call sites,
/// build mock implementations for SwiftUI previews and unit tests, or inject
/// alternative store implementations.
///
/// Because `@EnvironmentObject` requires a concrete `ObservableObject` type, views still
/// reference `StoreKitFlowStore` as the environment type. To use a mock in previews,
/// provide your mock as the environment value:
/// ```swift
/// MyView().environmentObject(MockStore() as StoreKitFlowStore)
/// // or subclass StoreKitFlowStore and override behaviour
/// ```
@MainActor
public protocol StoreObservable: ObservableObject {
    var products: [StoreProduct] { get }
    var purchasedProductIDs: Set<String> { get }
    var isLoading: Bool { get }
    var isPurchasing: Bool { get }
    var logs: [StoreLog] { get }
    var transactionHistory: [CachedTransaction] { get }

    func initialize() async
    @discardableResult
    func purchase(
        _ product: StoreProduct,
        attributes: PurchaseAttributes,
        shouldProcessUnfinishedTransactions: Bool
    ) async -> PurchaseOutcome
    func isPurchased(_ product: StoreProduct) -> Bool
    func restorePurchases() async
    func clearLogs()
    func clearTransactionHistory()
    func reconcile() async
}

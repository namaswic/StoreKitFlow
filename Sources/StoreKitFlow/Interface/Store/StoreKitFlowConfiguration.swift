public struct StoreKitFlowConfiguration: Sendable {
    public let productIDs: [String]
    public let subscriptionGroupIDs: [String]
    public let appStoreID: String?
    /// When `true`, every verified transaction is persisted to an on-device JSON cache
    /// at `Application Support/StoreKitFlow/transactions.json` and exposed via
    /// `StoreKitFlowStore.transactionHistory`. Defaults to `false`.
    public let enableTransactionCache: Bool

    public init(
        productIDs: [String],
        subscriptionGroupIDs: [String] = [],
        appStoreID: String? = nil,
        enableTransactionCache: Bool = false
    ) {
        self.productIDs = productIDs
        self.subscriptionGroupIDs = subscriptionGroupIDs
        self.appStoreID = appStoreID
        self.enableTransactionCache = enableTransactionCache
    }
}

public struct StoreKitFlowConfiguration: Sendable {
    public let productIDs: [String]
    public let subscriptionGroupIDs: [String]
    public let appStoreID: String?
    public let storeKitConfigFileName: String?

    public init(
        productIDs: [String],
        subscriptionGroupIDs: [String] = [],
        appStoreID: String? = nil,
        storeKitConfigFileName: String? = nil
    ) {
        self.productIDs = productIDs
        self.subscriptionGroupIDs = subscriptionGroupIDs
        self.appStoreID = appStoreID
        self.storeKitConfigFileName = storeKitConfigFileName
    }
}

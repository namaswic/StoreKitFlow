extension StoreKitFlowStore {
    public convenience init(configuration: StoreKitFlowConfiguration) {
        self.init(
            productService: ProductService(),
            purchaseService: PurchaseService(),
            entitlementService: EntitlementService(),
            transactionService: TransactionService(),
            configuration: configuration
        )
    }
}

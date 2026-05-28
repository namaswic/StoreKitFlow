extension StoreKitFlowStore {
    public convenience init(
        configuration: StoreKitFlowConfiguration,
        logger: (any StoreKitFlowLogging)? = nil
    ) {
        self.init(
            productService: ProductService(),
            purchaseService: PurchaseService(),
            entitlementService: EntitlementService(),
            transactionService: TransactionService(),
            logger: logger,
            configuration: configuration
        )
    }
}

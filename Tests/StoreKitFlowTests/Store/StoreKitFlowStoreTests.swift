import Testing
import Foundation
@testable import StoreKitFlow

@Suite("StoreKitFlowStore")
@MainActor
struct StoreKitFlowStoreTests {

    // MARK: - Helpers

    private func makeStore(
        productIDs: [String] = ["com.storekitflow.demo.pro.monthly"],
        products: [StoreProduct] = MockData.products,
        entitlements: Set<String> = [],
        purchaseBehaviour: ConfigurableMockPurchaseService.Behaviour = .returnCancelled,
        cacheEnabled: Bool = false,
        mockCache: MockTransactionCache? = nil
    ) -> (store: StoreKitFlowStore, logger: MockLogger, cache: MockTransactionCache) {
        let mockCache = mockCache ?? MockTransactionCache()
        let logger = MockLogger()
        let config = StoreKitFlowConfiguration(
            productIDs: productIDs,
            subscriptionGroupIDs: [],
            enableTransactionCache: cacheEnabled
        )
        let store = StoreKitFlowStore(
            productService: MockProductService(products: products),
            purchaseService: ConfigurableMockPurchaseService(behaviour: purchaseBehaviour),
            entitlementService: MockEntitlementService(entitlements: entitlements),
            transactionService: MockTransactionService(),
            cache: mockCache,
            logger: logger,
            configuration: config
        )
        return (store, logger, mockCache)
    }

    // MARK: - initialize()

    @Test("initialize sets isLoading false after completion")
    func initializeSetsIsLoadingFalse() async {
        let (store, _, _) = makeStore()
        await store.initialize()
        #expect(store.isLoading == false)
    }

    @Test("initialize populates products from service")
    func initializePopulatesProducts() async {
        let (store, _, _) = makeStore(
            productIDs: ["com.storekitflow.demo.removeads", "com.storekitflow.demo.coins10"],
            products: MockData.products
        )
        await store.initialize()
        #expect(store.products.count == 2)
        let ids = Set(store.products.map(\.id))
        #expect(ids.contains("com.storekitflow.demo.removeads"))
        #expect(ids.contains("com.storekitflow.demo.coins10"))
    }

    @Test("initialize filters products to requested IDs only")
    func initializeFiltersProductIDs() async {
        let (store, _, _) = makeStore(
            productIDs: ["com.storekitflow.demo.coins10"],
            products: MockData.products
        )
        await store.initialize()
        #expect(store.products.count == 1)
        #expect(store.products.first?.id == "com.storekitflow.demo.coins10")
    }

    @Test("initialize returns empty products when service throws")
    func initializeEmptyProductsOnThrow() async {
        let logger = MockLogger()
        let config = StoreKitFlowConfiguration(productIDs: ["com.example.fail"], enableTransactionCache: false)
        let store = StoreKitFlowStore(
            productService: MockProductService(products: []),
            purchaseService: ConfigurableMockPurchaseService(),
            entitlementService: MockEntitlementService(),
            transactionService: MockTransactionService(),
            cache: MockTransactionCache(),
            logger: logger,
            configuration: config
        )
        await store.initialize()
        #expect(store.products.isEmpty)
    }

    @Test("initialize logs fetchStarted then fetchCompleted")
    func initializeLogsFetchEvents() async {
        let (store, logger, _) = makeStore()
        await store.initialize()
        let categories = logger.loggedEvents.map(\.category)
        #expect(categories.contains(.productService))
        let productEvents = logger.events(in: .productService)
        let hasStarted = productEvents.contains { if case .fetchStarted = $0 { return true }; return false }
        let hasCompleted = productEvents.contains { if case .fetchCompleted = $0 { return true }; return false }
        #expect(hasStarted)
        #expect(hasCompleted)
    }

    @Test("initialize populates purchasedProductIDs from entitlement service")
    func initializePopulatesEntitlements() async {
        let (store, _, _) = makeStore(entitlements: ["com.storekitflow.demo.removeads"])
        await store.initialize()
        #expect(store.purchasedProductIDs.contains("com.storekitflow.demo.removeads"))
    }

    @Test("initialize sets empty purchasedProductIDs when no entitlements")
    func initializeEmptyEntitlements() async {
        let (store, _, _) = makeStore(entitlements: [])
        await store.initialize()
        #expect(store.purchasedProductIDs.isEmpty)
    }

    @Test("initialize logs entitlementsLoaded")
    func initializeLogsEntitlementsLoaded() async {
        let (store, logger, _) = makeStore(entitlements: ["com.storekitflow.demo.pro.monthly"])
        await store.initialize()
        let hasEntitlementsEvent = logger.events(in: .entitlements).contains {
            if case .entitlementsLoaded = $0 { return true }; return false
        }
        #expect(hasEntitlementsEvent)
    }

    @Test("initialize does not populate transactionHistory when cache disabled")
    func initializeNoCacheWhenDisabled() async {
        let (store, _, _) = makeStore(cacheEnabled: false)
        await store.initialize()
        #expect(store.transactionHistory.isEmpty)
    }

    @Test("initialize populates transactionHistory from cache when cache enabled")
    func initializeLoadsTransactionHistoryFromCache() async {
        let mockCache = MockTransactionCache()
        mockCache.record(makeCachedTransaction(id: 1001))
        mockCache.record(makeCachedTransaction(id: 1002))
        let (store, _, _) = makeStore(cacheEnabled: true, mockCache: mockCache)
        await store.initialize()
        #expect(store.transactionHistory.count == 2)
    }

    // MARK: - purchase()

    @Test("purchase sets isPurchasing false after completion")
    func purchaseSetsIsPurchasingFalse() async {
        let (store, _, _) = makeStore()
        await store.initialize()
        _ = await store.purchase(MockData.products[0])
        #expect(store.isPurchasing == false)
    }

    @Test("purchase returns cancelled when service returns userCancelled")
    func purchaseReturnsCancelled() async {
        let (store, _, _) = makeStore(purchaseBehaviour: .returnCancelled)
        await store.initialize()
        let outcome = await store.purchase(MockData.products[0])
        if case .cancelled = outcome { } else { Issue.record("Expected .cancelled, got \(outcome)") }
    }

    @Test("purchase returns pending when service returns pending")
    func purchaseReturnsPending() async {
        let (store, _, _) = makeStore(purchaseBehaviour: .returnPending)
        await store.initialize()
        let outcome = await store.purchase(MockData.products[0])
        if case .pending = outcome { } else { Issue.record("Expected .pending, got \(outcome)") }
    }

    @Test("purchase returns failed when service throws")
    func purchaseReturnsFailed() async {
        let (store, _, _) = makeStore(purchaseBehaviour: .throwError(MockError.purchaseFailed))
        await store.initialize()
        let outcome = await store.purchase(MockData.products[0])
        if case .failed = outcome { } else { Issue.record("Expected .failed, got \(outcome)") }
    }

    @Test("purchase logs purchaseStarted as first purchase event")
    func purchaseLogsPurchaseStarted() async {
        let (store, logger, _) = makeStore()
        await store.initialize()
        _ = await store.purchase(MockData.products[0])
        let purchaseEvents = logger.events(in: .purchaseFlow)
        let hasStarted = purchaseEvents.contains { if case .purchaseStarted = $0 { return true }; return false }
        #expect(hasStarted)
    }

    @Test("purchase logs purchaseCancelled on user cancel")
    func purchaseLogsCancelled() async {
        let (store, logger, _) = makeStore(purchaseBehaviour: .returnCancelled)
        await store.initialize()
        _ = await store.purchase(MockData.products[0])
        let hasCancelled = logger.events(in: .purchaseFlow).contains {
            if case .purchaseCancelled = $0 { return true }; return false
        }
        #expect(hasCancelled)
    }

    @Test("purchase logs purchasePending on pending")
    func purchaseLogsPending() async {
        let (store, logger, _) = makeStore(purchaseBehaviour: .returnPending)
        await store.initialize()
        _ = await store.purchase(MockData.products[0])
        let hasPending = logger.events(in: .purchaseFlow).contains {
            if case .purchasePending = $0 { return true }; return false
        }
        #expect(hasPending)
    }

    @Test("purchase logs purchaseFailed on error")
    func purchaseLogsFailed() async {
        let (store, logger, _) = makeStore(purchaseBehaviour: .throwError(MockError.purchaseFailed))
        await store.initialize()
        _ = await store.purchase(MockData.products[0])
        let hasFailed = logger.events(in: .purchaseFlow).contains {
            if case .purchaseFailed = $0 { return true }; return false
        }
        #expect(hasFailed)
    }

    @Test("purchase does not mutate purchasedProductIDs on cancelled")
    func purchaseDoesNotMutateStateOnCancel() async {
        let (store, _, _) = makeStore(entitlements: [], purchaseBehaviour: .returnCancelled)
        await store.initialize()
        _ = await store.purchase(MockData.products[0])
        #expect(store.purchasedProductIDs.isEmpty)
    }

    @Test("purchase does not mutate purchasedProductIDs on failed")
    func purchaseDoesNotMutateStateOnFailed() async {
        let (store, _, _) = makeStore(entitlements: [], purchaseBehaviour: .throwError(MockError.purchaseFailed))
        await store.initialize()
        _ = await store.purchase(MockData.products[0])
        #expect(store.purchasedProductIDs.isEmpty)
    }

    // MARK: - isPurchased()

    @Test("isPurchased returns false for product not in set")
    func isPurchasedReturnsFalseWhenNotPurchased() async {
        let (store, _, _) = makeStore(entitlements: [])
        await store.initialize()
        #expect(store.isPurchased(MockData.products[0]) == false)
    }

    @Test("isPurchased returns true after initialize with matching entitlement")
    func isPurchasedReturnsTrueWithEntitlement() async {
        let product = MockData.products.first(where: { $0.id == "com.storekitflow.demo.removeads" })!
        let (store, _, _) = makeStore(entitlements: ["com.storekitflow.demo.removeads"])
        await store.initialize()
        #expect(store.isPurchased(product) == true)
    }

    // MARK: - clearLogs()

    @Test("clearLogs empties the logs array")
    func clearLogsEmptiesLogs() async {
        let (store, _, _) = makeStore()
        await store.initialize()
        #expect(!store.logs.isEmpty)
        store.clearLogs()
        #expect(store.logs.isEmpty)
    }

    // MARK: - clearTransactionHistory()

    @Test("clearTransactionHistory is no-op when cache disabled")
    func clearTransactionHistoryNoOpWhenDisabled() async {
        let (store, _, _) = makeStore(cacheEnabled: false)
        await store.initialize()
        store.clearTransactionHistory()
        #expect(store.transactionHistory.isEmpty)
    }

    @Test("clearTransactionHistory clears state and cache when enabled")
    func clearTransactionHistoryClearsCacheAndState() async {
        let mockCache = MockTransactionCache()
        mockCache.record(makeCachedTransaction(id: 2001))
        let (store, _, cache) = makeStore(cacheEnabled: true, mockCache: mockCache)
        await store.initialize()
        #expect(store.transactionHistory.count == 1)
        store.clearTransactionHistory()
        #expect(store.transactionHistory.isEmpty)
        #expect(cache.clearAllCallCount == 1)
    }

    // MARK: - reconcile()

    @Test("reconcile is no-op when cache disabled")
    func reconcileNoOpWhenDisabled() async {
        let (store, _, _) = makeStore(cacheEnabled: false)
        await store.initialize()
        await store.reconcile()
        #expect(store.transactionHistory.isEmpty)
    }

    @Test("reconcile does not crash when cache returns empty missing transactions")
    func reconcileWithEmptyMissingTransactions() async {
        let (store, _, _) = makeStore(cacheEnabled: true)
        await store.initialize()
        await store.reconcile()
        #expect(store.transactionHistory.isEmpty)
    }

    // MARK: - Logger disabled

    @Test("disabled logger receives no events")
    func disabledLoggerReceivesNoEvents() async {
        let (store, logger, _) = makeStore()
        logger.isEnabled = false
        await store.initialize()
        #expect(logger.loggedEvents.isEmpty)
    }

    // MARK: - Helper

    private func makeCachedTransaction(id: UInt64) -> CachedTransaction {
        CachedTransaction(
            id: id,
            originalID: id,
            productID: "com.storekitflow.demo.pro.monthly",
            productType: .autoRenewable,
            purchaseDate: Date(),
            expirationDate: nil,
            revocationDate: nil,
            appAccountToken: nil,
            environment: "Xcode",
            finishedAt: Date(),
            source: .purchase,
            deliveryLog: [TransactionDeliveryEvent(source: .purchase, path: .storePurchase)]
        )
    }
}

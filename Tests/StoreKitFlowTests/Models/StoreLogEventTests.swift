import Testing
@testable import StoreKitFlow

@Suite("StoreLogEvent")
struct StoreLogEventTests {

    // MARK: - category

    @Test("product service events map to .productService")
    func productServiceCategory() {
        #expect(StoreLogEvent.fetchStarted(ids: []).category == .productService)
        #expect(StoreLogEvent.fetchCompleted(count: 3).category == .productService)
        #expect(StoreLogEvent.fetchFailed(error: "err").category == .productService)
    }

    @Test("purchase flow events map to .purchaseFlow")
    func purchaseFlowCategory() {
        #expect(StoreLogEvent.purchaseStarted(productID: "x").category == .purchaseFlow)
        #expect(StoreLogEvent.purchaseSucceeded(productID: "x").category == .purchaseFlow)
        #expect(StoreLogEvent.purchaseCancelled(productID: "x").category == .purchaseFlow)
        #expect(StoreLogEvent.purchasePending(productID: "x").category == .purchaseFlow)
        #expect(StoreLogEvent.purchaseFailed(productID: "x", error: "e").category == .purchaseFlow)
    }

    @Test("transaction events map to .transactions")
    func transactionCategory() {
        #expect(StoreLogEvent.transactionReceived(productID: "x", transactionID: 1, originalTransactionID: 1).category == .transactions)
        #expect(StoreLogEvent.transactionVerified(productID: "x", transactionID: 1, originalTransactionID: 1).category == .transactions)
        #expect(StoreLogEvent.transactionUnverified(productID: "x").category == .transactions)
        #expect(StoreLogEvent.transactionFinished(productID: "x", transactionID: 1, originalTransactionID: 1, reason: "r").category == .transactions)
        #expect(StoreLogEvent.unfinishedTransactionFound(productID: "x", transactionID: 1, originalTransactionID: 1).category == .transactions)
    }

    @Test("entitlements event maps to .entitlements")
    func entitlementsCategory() {
        #expect(StoreLogEvent.entitlementsLoaded(productIDs: []).category == .entitlements)
    }

    @Test("restore events map to .restore")
    func restoreCategory() {
        #expect(StoreLogEvent.restoreStarted.category == .restore)
        #expect(StoreLogEvent.restoreCompleted(productIDs: []).category == .restore)
        #expect(StoreLogEvent.restoreFailed(error: "e").category == .restore)
    }

    @Test("cache events map to .cache")
    func cacheCategory() {
        #expect(StoreLogEvent.transactionCached(productID: "x", transactionID: 1, source: .purchase).category == .cache)
        #expect(StoreLogEvent.reconciliationFound(count: 2).category == .cache)
        #expect(StoreLogEvent.reconciliationComplete.category == .cache)
    }

    // MARK: - isError

    @Test("isError is true for error cases only")
    func isErrorTrueForErrorCases() {
        #expect(StoreLogEvent.fetchFailed(error: "e").isError == true)
        #expect(StoreLogEvent.transactionUnverified(productID: "x").isError == true)
        #expect(StoreLogEvent.purchaseFailed(productID: "x", error: "e").isError == true)
        #expect(StoreLogEvent.restoreFailed(error: "e").isError == true)
    }

    @Test("isError is false for non-error cases")
    func isErrorFalseForNonErrorCases() {
        #expect(StoreLogEvent.fetchCompleted(count: 1).isError == false)
        #expect(StoreLogEvent.purchaseSucceeded(productID: "x").isError == false)
        #expect(StoreLogEvent.restoreCompleted(productIDs: []).isError == false)
        #expect(StoreLogEvent.entitlementsLoaded(productIDs: []).isError == false)
        #expect(StoreLogEvent.reconciliationComplete.isError == false)
    }

    // MARK: - description

    @Test("description includes product ID for purchaseStarted")
    func descriptionIncludesProductID() {
        let event = StoreLogEvent.purchaseStarted(productID: "com.example.pro")
        #expect(event.description.contains("com.example.pro"))
    }

    @Test("description includes count for fetchCompleted")
    func descriptionIncludesCountForFetchCompleted() {
        let event = StoreLogEvent.fetchCompleted(count: 7)
        #expect(event.description.contains("7"))
    }

    @Test("description includes error text for fetchFailed")
    func descriptionIncludesErrorForFetchFailed() {
        let event = StoreLogEvent.fetchFailed(error: "network error")
        #expect(event.description.contains("network error"))
    }

    // MARK: - details

    @Test("restoreStarted has empty details")
    func restoreStartedHasEmptyDetails() {
        #expect(StoreLogEvent.restoreStarted.details.isEmpty)
    }

    @Test("transactionVerified details contain product ID")
    func transactionVerifiedDetailsContainProductID() {
        let event = StoreLogEvent.transactionVerified(productID: "com.example.pro", transactionID: 42, originalTransactionID: 41)
        let productIDDetail = event.details.first { $0.label == "Product ID" }
        #expect(productIDDetail?.value == "com.example.pro")
    }

    @Test("reconciliationFound details contain missing count")
    func reconciliationFoundDetailsContainCount() {
        let event = StoreLogEvent.reconciliationFound(count: 3)
        let countDetail = event.details.first { $0.label == "Missing Renewals" }
        #expect(countDetail?.value == "3")
    }

    @Test("fetchStarted details contain product count and IDs")
    func fetchStartedDetails() {
        let ids = ["com.example.a", "com.example.b"]
        let event = StoreLogEvent.fetchStarted(ids: ids)
        let countDetail = event.details.first { $0.label == "Product Count" }
        #expect(countDetail?.value == "2")
    }

    // MARK: - prefix

    @Test("prefix matches category raw value")
    func prefixMatchesCategoryRawValue() {
        let event = StoreLogEvent.fetchCompleted(count: 1)
        #expect(event.prefix == "[\(event.category.rawValue)]")
    }

    // MARK: - StoreLog

    @Test("StoreLog instances have unique IDs")
    func storeLogHasUniqueIDs() {
        let log1 = StoreLog(event: .fetchCompleted(count: 1))
        let log2 = StoreLog(event: .fetchCompleted(count: 1))
        #expect(log1.id != log2.id)
    }
}

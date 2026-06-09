import Testing
import Foundation
@testable import StoreKitFlow

@Suite("CachedTransaction")
struct CachedTransactionTests {

    private func makeTransaction(
        id: UInt64 = 1,
        deliveryLog: [TransactionDeliveryEvent] = []
    ) -> CachedTransaction {
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
            finishedAt: nil,
            source: .purchase,
            deliveryLog: deliveryLog
        )
    }

    @Test("deliveryCount equals deliveryLog count")
    func deliveryCountEqualsLogCount() {
        let events = [
            TransactionDeliveryEvent(source: .purchase, path: .storePurchase),
            TransactionDeliveryEvent(source: .renewal, path: .transactionUpdates),
            TransactionDeliveryEvent(source: .unfinished, path: .transactionUnfinished)
        ]
        let tx = makeTransaction(deliveryLog: events)
        #expect(tx.deliveryCount == 3)
    }

    @Test("deliveryCount is zero for empty log")
    func deliveryCountZeroForEmptyLog() {
        let tx = makeTransaction(deliveryLog: [])
        #expect(tx.deliveryCount == 0)
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let token = UUID()
        let now = Date()
        let tx = CachedTransaction(
            id: 999,
            originalID: 888,
            productID: "com.example.pro",
            productType: .nonConsumable,
            purchaseDate: now,
            expirationDate: now.addingTimeInterval(3600),
            revocationDate: now.addingTimeInterval(7200),
            appAccountToken: token,
            environment: "Sandbox",
            finishedAt: now.addingTimeInterval(10),
            source: .restore,
            deliveryLog: [TransactionDeliveryEvent(source: .restore, path: .transactionUnfinished)]
        )
        let data = try JSONEncoder().encode(tx)
        let decoded = try JSONDecoder().decode(CachedTransaction.self, from: data)
        #expect(decoded.id == tx.id)
        #expect(decoded.originalID == tx.originalID)
        #expect(decoded.productID == tx.productID)
        #expect(decoded.productType == tx.productType)
        #expect(decoded.appAccountToken == tx.appAccountToken)
        #expect(decoded.environment == tx.environment)
        #expect(decoded.source == tx.source)
        #expect(decoded.deliveryCount == tx.deliveryCount)
    }

    @Test("Codable round-trip with nil optional fields")
    func codableRoundTripWithNilOptionals() throws {
        let tx = makeTransaction()
        let data = try JSONEncoder().encode(tx)
        let decoded = try JSONDecoder().decode(CachedTransaction.self, from: data)
        #expect(decoded.expirationDate == nil)
        #expect(decoded.revocationDate == nil)
        #expect(decoded.appAccountToken == nil)
        #expect(decoded.finishedAt == nil)
    }

    @Test("CacheSource has stable raw values")
    func cacheSourceRawValues() {
        #expect(CacheSource.purchase.rawValue == "purchase")
        #expect(CacheSource.renewal.rawValue == "renewal")
        #expect(CacheSource.restore.rawValue == "restore")
        #expect(CacheSource.unfinished.rawValue == "unfinished")
    }

    @Test("TransactionDeliveryPath has stable raw values")
    func deliveryPathRawValues() {
        #expect(TransactionDeliveryPath.storePurchase.rawValue == "store.purchase()")
        #expect(TransactionDeliveryPath.transactionUpdates.rawValue == "Transaction.updates")
        #expect(TransactionDeliveryPath.transactionUnfinished.rawValue == "Transaction.unfinished")
        #expect(TransactionDeliveryPath.reconciliation.rawValue == "reconciliation")
    }

    @Test("TransactionDeliveryEvent IDs are unique")
    func deliveryEventIDsAreUnique() {
        let e1 = TransactionDeliveryEvent(source: .purchase, path: .storePurchase)
        let e2 = TransactionDeliveryEvent(source: .purchase, path: .storePurchase)
        #expect(e1.id != e2.id)
    }
}

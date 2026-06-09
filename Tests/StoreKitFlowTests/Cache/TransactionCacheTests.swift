import Testing
import Foundation
@testable import StoreKitFlow

@Suite("TransactionCache")
@MainActor
struct TransactionCacheTests {

    // MARK: - Helpers

    private func makeTempCache() -> (cache: TransactionCache, url: URL) {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString + ".json")
        let cache = TransactionCache(storageURL: url)
        return (cache, url)
    }

    private func makeCachedTransaction(
        id: UInt64,
        productID: String = "com.storekitflow.demo.pro.monthly",
        source: CacheSource = .purchase,
        path: TransactionDeliveryPath = .storePurchase,
        finishedAt: Date? = Date()
    ) -> CachedTransaction {
        CachedTransaction(
            id: id,
            originalID: id,
            productID: productID,
            productType: .autoRenewable,
            purchaseDate: Date(),
            expirationDate: nil,
            revocationDate: nil,
            appAccountToken: nil,
            environment: "Xcode",
            finishedAt: finishedAt,
            source: source,
            deliveryLog: [TransactionDeliveryEvent(source: source, path: path)]
        )
    }

    // MARK: - Basic reads

    @Test("all() returns empty on fresh cache")
    func allReturnsEmptyOnFreshCache() {
        let (cache, url) = makeTempCache()
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(cache.all().isEmpty)
    }

    // MARK: - record()

    @Test("record appends a new entry")
    func recordAppendsNewEntry() {
        let (cache, url) = makeTempCache()
        defer { try? FileManager.default.removeItem(at: url) }
        cache.record(makeCachedTransaction(id: 1))
        #expect(cache.all().count == 1)
    }

    @Test("record appends multiple distinct entries")
    func recordAppendsMultipleEntries() {
        let (cache, url) = makeTempCache()
        defer { try? FileManager.default.removeItem(at: url) }
        cache.record(makeCachedTransaction(id: 1))
        cache.record(makeCachedTransaction(id: 2))
        cache.record(makeCachedTransaction(id: 3))
        #expect(cache.all().count == 3)
    }

    @Test("record merges delivery log for duplicate ID")
    func recordMergesDeliveryLogForDuplicateID() {
        let (cache, url) = makeTempCache()
        defer { try? FileManager.default.removeItem(at: url) }
        cache.record(makeCachedTransaction(id: 100, source: .purchase, path: .storePurchase))
        cache.record(makeCachedTransaction(id: 100, source: .renewal, path: .transactionUpdates))
        #expect(cache.all().count == 1)
        #expect(cache.all()[0].deliveryCount == 2)
    }

    @Test("record preserves original finishedAt on merge when already set")
    func recordPreservesFinishedAtOnMerge() {
        let (cache, url) = makeTempCache()
        defer { try? FileManager.default.removeItem(at: url) }
        let originalDate = Date(timeIntervalSinceNow: -3600)
        cache.record(makeCachedTransaction(id: 200, finishedAt: originalDate))
        cache.record(makeCachedTransaction(id: 200, finishedAt: nil))
        #expect(cache.all()[0].finishedAt != nil)
        #expect(abs(cache.all()[0].finishedAt!.timeIntervalSince(originalDate)) < 1)
    }

    @Test("record uses new finishedAt when original is nil")
    func recordUsesNewFinishedAtWhenOriginalNil() {
        let (cache, url) = makeTempCache()
        defer { try? FileManager.default.removeItem(at: url) }
        cache.record(makeCachedTransaction(id: 300, finishedAt: nil))
        let newDate = Date()
        cache.record(makeCachedTransaction(id: 300, finishedAt: newDate))
        #expect(cache.all()[0].finishedAt != nil)
    }

    // MARK: - Persistence

    @Test("record persists to disk and reloads")
    func recordPersistsToDisk() {
        let (cache, url) = makeTempCache()
        defer { try? FileManager.default.removeItem(at: url) }
        cache.record(makeCachedTransaction(id: 400))
        let reloaded = TransactionCache(storageURL: url)
        #expect(reloaded.all().count == 1)
        #expect(reloaded.all()[0].id == 400)
    }

    @Test("init loads persisted entries")
    func initLoadsPersistedEntries() {
        let (cache, url) = makeTempCache()
        defer { try? FileManager.default.removeItem(at: url) }
        cache.record(makeCachedTransaction(id: 500))
        cache.record(makeCachedTransaction(id: 501))
        let reloaded = TransactionCache(storageURL: url)
        #expect(reloaded.all().count == 2)
    }

    @Test("init starts fresh when file is missing")
    func initStartsFreshWhenFileMissing() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString + "_nonexistent.json")
        let cache = TransactionCache(storageURL: url)
        #expect(cache.all().isEmpty)
    }

    @Test("init starts fresh when file is corrupt")
    func initStartsFreshWhenFileCorrupt() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        try "not valid json {{{{".write(to: url, atomically: true, encoding: .utf8)
        let cache = TransactionCache(storageURL: url)
        #expect(cache.all().isEmpty)
    }

    // MARK: - clearAll()

    @Test("clearAll empties entries")
    func clearAllEmptiesEntries() {
        let (cache, url) = makeTempCache()
        defer { try? FileManager.default.removeItem(at: url) }
        cache.record(makeCachedTransaction(id: 600))
        cache.record(makeCachedTransaction(id: 601))
        cache.clearAll()
        #expect(cache.all().isEmpty)
    }

    @Test("clearAll deletes backing file")
    func clearAllDeletesBackingFile() {
        let (cache, url) = makeTempCache()
        cache.record(makeCachedTransaction(id: 700))
        cache.clearAll()
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test("clearAll then record works correctly")
    func clearAllThenRecord() {
        let (cache, url) = makeTempCache()
        defer { try? FileManager.default.removeItem(at: url) }
        cache.record(makeCachedTransaction(id: 800))
        cache.clearAll()
        cache.record(makeCachedTransaction(id: 801))
        #expect(cache.all().count == 1)
        #expect(cache.all()[0].id == 801)
    }
}

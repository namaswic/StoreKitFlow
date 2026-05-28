import Foundation
import StoreKit

/// Persistent, on-device history of every transaction seen by StoreKitFlow.
///
/// Stored as a JSON array at `Application Support/StoreKitFlow/transactions.json`.
/// The cache is append-only — records are never deleted, only updated with `finishedAt`.
///
/// ## Why this matters
/// StoreKit has no local transaction history. If your app is killed mid-renewal,
/// or the `Transaction.updates` task is cancelled, that renewal is silently lost.
/// `TransactionCache` provides:
/// - A full audit trail for production incident debugging
/// - A reconciliation engine to detect missed renewals
/// - A source of truth for `store.transactionHistory`
///
/// ## Thread safety
/// All methods are `@MainActor` — safe to call from `StoreKitFlowStore` which is also `@MainActor`.
@MainActor
final class TransactionCache {

    static let shared = TransactionCache()

    private let storageURL: URL
    private var entries: [CachedTransaction] = []

    init(storageURL: URL? = nil) {
        if let url = storageURL {
            self.storageURL = url
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("StoreKitFlow", isDirectory: true)
            self.storageURL = dir.appendingPathComponent("transactions.json")
        }
        self.entries = (try? Self.load(from: self.storageURL)) ?? []
    }

    // MARK: - Public API

    /// All cached transactions, ordered oldest first.
    func all() -> [CachedTransaction] { entries }

    /// Records a transaction. If a record with the same `id` already exists, the new delivery
    /// event is appended to its `deliveryLog` and metadata is refreshed (e.g. `finishedAt`).
    /// If it is new, the full entry is appended.
    func record(_ entry: CachedTransaction) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var existing = entries[index]
            existing.deliveryLog.append(contentsOf: entry.deliveryLog)
            // Refresh finishedAt if this call has it and the existing record doesn't
            if existing.finishedAt == nil, let finished = entry.finishedAt {
                entries[index] = CachedTransaction(
                    id: existing.id,
                    originalID: existing.originalID,
                    productID: existing.productID,
                    productType: existing.productType,
                    purchaseDate: existing.purchaseDate,
                    expirationDate: existing.expirationDate,
                    revocationDate: existing.revocationDate,
                    appAccountToken: existing.appAccountToken,
                    environment: existing.environment,
                    finishedAt: finished,
                    source: existing.source,
                    deliveryLog: existing.deliveryLog
                )
            } else {
                entries[index] = existing
            }
        } else {
            entries.append(entry)
        }
        persist()
    }

    /// Finds auto-renewable subscription renewals that StoreKit delivered but this app
    /// never recorded — indicating a missed renewal (crash, task cancellation, background kill).
    ///
    /// **How it works:**
    /// 1. Reads `Transaction.currentEntitlements` to get the authoritative set of active subscriptions.
    /// 2. For each active subscription, finds the most recent cached renewal.
    /// 3. If the entitlement's transaction ID is not in the cache, that renewal was missed.
    ///
    /// Returns the missing `Transaction` objects so the store can re-process and finish them.
    ///
    /// Call this from `initialize()` after draining unfinished transactions.
    func reconcile() async -> [Transaction] {
        var missing: [Transaction] = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productType == .autoRenewable else { continue }

            // If this transaction ID is not in our cache, we missed it
            if !entries.contains(where: { $0.id == transaction.id }) {
                missing.append(transaction)
            }
        }

        return missing
    }

    /// Removes all cached entries and deletes the backing file.
    /// Use only during development/testing — production data should not be cleared.
    func clearAll() {
        entries = []
        try? FileManager.default.removeItem(at: storageURL)
    }

    // MARK: - Persistence

    private func persist() {
        do {
            let dir = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(entries)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            // Persistence failure is non-fatal — cache is still correct in-memory for this session
        }
    }

    private static func load(from url: URL) throws -> [CachedTransaction] {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([CachedTransaction].self, from: data)
    }
}

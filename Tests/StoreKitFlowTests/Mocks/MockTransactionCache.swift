import Foundation
import StoreKit
@testable import StoreKitFlow

@MainActor
final class MockTransactionCache: TransactionCaching {
    private(set) var recorded: [CachedTransaction] = []
    private(set) var clearAllCallCount = 0

    func all() -> [CachedTransaction] { recorded }

    func record(_ entry: CachedTransaction) {
        if let index = recorded.firstIndex(where: { $0.id == entry.id }) {
            let existing = recorded[index]
            recorded[index] = CachedTransaction(
                id: existing.id,
                originalID: existing.originalID,
                productID: existing.productID,
                productType: existing.productType,
                purchaseDate: existing.purchaseDate,
                expirationDate: existing.expirationDate,
                revocationDate: existing.revocationDate,
                appAccountToken: existing.appAccountToken,
                environment: existing.environment,
                finishedAt: existing.finishedAt ?? entry.finishedAt,
                source: existing.source,
                deliveryLog: existing.deliveryLog + entry.deliveryLog
            )
        } else {
            recorded.append(entry)
        }
    }

    func reconcile() async -> [Transaction] { [] }

    func clearAll() {
        recorded = []
        clearAllCallCount += 1
    }
}

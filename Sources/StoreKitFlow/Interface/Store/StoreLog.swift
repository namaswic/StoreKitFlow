import Foundation

public struct StoreLog: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let event: StoreLogEvent

    public init(event: StoreLogEvent) {
        self.id = UUID()
        self.timestamp = Date()
        self.event = event
    }
}

public enum StoreLogCategory: String, Sendable, CaseIterable {
    case productService  = "Product Service"
    case purchaseFlow    = "Purchase Flow"
    case transactions    = "Transaction Listener"
    case entitlements    = "Entitlements"
    case restore         = "Restore"
    case cache           = "Transaction Cache"
}

public enum StoreLogEvent: Sendable {
    // Product Service
    case fetchStarted(ids: [String])
    case fetchCompleted(count: Int)
    case fetchFailed(error: String)

    // Purchase Flow
    case purchaseStarted(productID: String)
    case purchaseSucceeded(productID: String)
    case purchaseCancelled(productID: String)
    case purchasePending(productID: String)
    case purchaseFailed(productID: String, error: String)
    case accountTokenMismatch(productID: String, requested: UUID?, received: UUID?)

    // Transaction Listener
    case transactionReceived(productID: String, transactionID: UInt64, originalTransactionID: UInt64)
    case transactionVerified(productID: String, transactionID: UInt64, originalTransactionID: UInt64)
    case transactionUnverified(productID: String)
    case transactionFinished(productID: String, transactionID: UInt64, originalTransactionID: UInt64, reason: String)
    case unfinishedTransactionFound(productID: String, transactionID: UInt64, originalTransactionID: UInt64)

    // Entitlements
    case entitlementsLoaded(productIDs: Set<String>)

    // Restore
    case restoreStarted
    case restoreCompleted(productIDs: Set<String>)
    case restoreFailed(error: String)

    // Transaction Cache
    case transactionCached(productID: String, transactionID: UInt64, source: CacheSource)
    case reconciliationFound(count: Int)
    case reconciliationComplete

    public var category: StoreLogCategory {
        switch self {
        case .fetchStarted, .fetchCompleted, .fetchFailed:
            return .productService
        case .purchaseStarted, .purchaseSucceeded, .purchaseCancelled, .purchasePending, .purchaseFailed, .accountTokenMismatch:
            return .purchaseFlow
        case .transactionReceived, .transactionVerified, .transactionUnverified, .transactionFinished, .unfinishedTransactionFound:
            return .transactions
        case .entitlementsLoaded:
            return .entitlements
        case .restoreStarted, .restoreCompleted, .restoreFailed:
            return .restore
        case .transactionCached, .reconciliationFound, .reconciliationComplete:
            return .cache
        }
    }

    public var prefix: String { "[\(category.rawValue)]" }

    public var description: String {
        switch self {
        case .fetchStarted(let ids):
            return "\(prefix) Fetching \(ids.count) product(s)"
        case .fetchCompleted(let count):
            return "\(prefix) Fetched \(count) product(s) successfully"
        case .fetchFailed(let error):
            return "\(prefix) Fetch failed: \(error)"
        case .purchaseStarted(let productID):
            return "\(prefix) Started — \(productID)"
        case .purchaseSucceeded(let productID):
            return "\(prefix) Succeeded — \(productID)"
        case .purchaseCancelled(let productID):
            return "\(prefix) Cancelled by user — \(productID)"
        case .purchasePending(let productID):
            return "\(prefix) Pending — \(productID)"
        case .purchaseFailed(let productID, let error):
            return "\(prefix) Failed — \(productID): \(error)"
        case .accountTokenMismatch(let productID, let requested, let received):
            return "\(prefix) Account token mismatch — \(productID): requested \(requested?.uuidString ?? "nil"), received \(received?.uuidString ?? "nil")"
        case .transactionReceived(let productID, let id, _):
            return "\(prefix) Received #\(id) — \(productID)"
        case .transactionVerified(let productID, let id, _):
            return "\(prefix) Verified #\(id) — \(productID)"
        case .transactionUnverified(let productID):
            return "\(prefix) Unverified — \(productID)"
        case .transactionFinished(let productID, let id, _, _):
            return "\(prefix) Finished #\(id) — \(productID)"
        case .unfinishedTransactionFound(let productID, let id, _):
            return "\(prefix) Unfinished #\(id) found — \(productID)"
        case .entitlementsLoaded(let productIDs):
            return "\(prefix) \(productIDs.isEmpty ? "No active entitlements" : productIDs.joined(separator: ", "))"
        case .restoreStarted:
            return "\(prefix) Restore started"
        case .restoreCompleted(let productIDs):
            return "\(prefix) Restored \(productIDs.count) entitlement(s)"
        case .restoreFailed(let error):
            return "\(prefix) Restore failed: \(error)"
        case .transactionCached(let productID, let id, let source):
            return "\(prefix) Cached #\(id) (\(source.rawValue)) — \(productID)"
        case .reconciliationFound(let count):
            return "\(prefix) Reconciliation: \(count) missed renewal(s) found"
        case .reconciliationComplete:
            return "\(prefix) Reconciliation complete — no gaps found"
        }
    }

    public var icon: String {
        switch self {
        case .fetchStarted:                 return "arrow.down.circle"
        case .fetchCompleted:               return "checkmark.circle.fill"
        case .fetchFailed:                  return "xmark.circle.fill"
        case .purchaseStarted:              return "cart"
        case .purchaseSucceeded:            return "cart.fill.badge.plus"
        case .purchaseCancelled:            return "xmark.circle"
        case .purchasePending:              return "clock"
        case .purchaseFailed:               return "cart.badge.minus"
        case .accountTokenMismatch:         return "person.crop.circle.badge.exclamationmark"
        case .transactionReceived:          return "arrow.left.circle"
        case .transactionVerified:          return "checkmark.seal.fill"
        case .transactionUnverified:        return "exclamationmark.shield.fill"
        case .transactionFinished:          return "flag.checkered"
        case .unfinishedTransactionFound:   return "exclamationmark.circle"
        case .entitlementsLoaded:           return "person.badge.shield.checkmark"
        case .restoreStarted:               return "arrow.clockwise"
        case .restoreCompleted:             return "checkmark.circle.fill"
        case .restoreFailed:                return "xmark.circle.fill"
        case .transactionCached:            return "archivebox.fill"
        case .reconciliationFound:          return "exclamationmark.magnifyingglass"
        case .reconciliationComplete:       return "checkmark.magnifyingglass"
        }
    }

    public var searchableText: String {
        details.map { "\($0.label) \($0.value)" }.joined(separator: " ")
    }

    public var isError: Bool {
        switch self {
        case .fetchFailed, .transactionUnverified, .purchaseFailed, .restoreFailed: return true
        default: return false
        }
    }

    public struct Detail: Sendable {
        public let label: String
        public let value: String
    }

    public var details: [Detail] {
        switch self {
        case .fetchStarted(let ids):
            return [
                Detail(label: "Product Count", value: "\(ids.count)"),
                Detail(label: "Product IDs", value: ids.joined(separator: "\n"))
            ]
        case .fetchCompleted(let count):
            return [Detail(label: "Products Loaded", value: "\(count)")]
        case .fetchFailed(let error):
            return [Detail(label: "Error", value: error)]
        case .purchaseStarted(let productID),
             .purchaseSucceeded(let productID),
             .purchaseCancelled(let productID):
            return [Detail(label: "Product ID", value: productID)]
        case .purchasePending(let productID):
            return [
                Detail(label: "Product ID", value: productID),
                Detail(label: "Common causes", value: "Ask to Buy awaiting parental approval · Family Sharing organizer approval required · Billing issue (expired card, insufficient funds) · Bank authorization delay"),
                Detail(label: "If still pending", value: "Ask the user to check Settings → Apple ID → Payment & Shipping, or contact Apple Support at https://support.apple.com/billing"),
                Detail(label: "When Apple won't process", value: "Purchase never approved (Ask to Buy / Family Sharing) · Billing issue (expired card, insufficient funds) · Transaction flagged for fraud or App Store policy violation · Apple server-side delay")
            ]
        case .purchaseFailed(let productID, let error):
            return [
                Detail(label: "Product ID", value: productID),
                Detail(label: "Error", value: error)
            ]
        case .accountTokenMismatch(let productID, let requested, let received):
            return [
                Detail(label: "Product ID", value: productID),
                Detail(label: "Requested Token", value: requested?.uuidString ?? "nil"),
                Detail(label: "Received Token", value: received?.uuidString ?? "nil"),
                Detail(label: "Cause", value: "Different app account (same Apple ID) has active subscription")
            ]
        case .transactionFinished(let productID, let id, let originalID, let reason):
            return [
                Detail(label: "Transaction ID", value: "#\(id)"),
                Detail(label: "Original Txn ID", value: "#\(originalID)"),
                Detail(label: "Product ID", value: productID),
                Detail(label: "Reason", value: reason)
            ]
        case .transactionReceived(let productID, let id, let originalID),
             .transactionVerified(let productID, let id, let originalID),
             .unfinishedTransactionFound(let productID, let id, let originalID):
            return [
                Detail(label: "Transaction ID", value: "#\(id)"),
                Detail(label: "Original Txn ID", value: "#\(originalID)"),
                Detail(label: "Product ID", value: productID)
            ]
        case .transactionUnverified(let productID):
            return [
                Detail(label: "Product ID", value: productID),
                Detail(label: "Why not finished", value: skipFinishReason(for: .unverified))
            ]
        case .entitlementsLoaded(let productIDs):
            return [
                Detail(label: "Count", value: "\(productIDs.count)"),
                Detail(label: "Product IDs", value: productIDs.isEmpty ? "None" : productIDs.sorted().joined(separator: "\n"))
            ]
        case .restoreStarted:
            return []
        case .restoreCompleted(let productIDs):
            return [
                Detail(label: "Restored Count", value: "\(productIDs.count)"),
                Detail(label: "Product IDs", value: productIDs.isEmpty ? "None" : productIDs.sorted().joined(separator: "\n"))
            ]
        case .restoreFailed(let error):
            return [Detail(label: "Error", value: error)]
        case .transactionCached(let productID, let id, let source):
            return [
                Detail(label: "Transaction ID", value: "#\(id)"),
                Detail(label: "Product ID", value: productID),
                Detail(label: "Source", value: source.rawValue)
            ]
        case .reconciliationFound(let count):
            return [
                Detail(label: "Missing Renewals", value: "\(count)"),
                Detail(label: "Action", value: "These transactions were delivered by StoreKit but never recorded — likely missed due to app crash, background kill, or cancelled transaction listener task")
            ]
        case .reconciliationComplete:
            return [Detail(label: "Status", value: "All StoreKit entitlements matched cache — no missed renewals detected")]
        }
    }
}

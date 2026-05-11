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

    // Transaction Listener
    case transactionReceived(productID: String, transactionID: UInt64, originalTransactionID: UInt64)
    case transactionVerified(productID: String, transactionID: UInt64, originalTransactionID: UInt64)
    case transactionUnverified(productID: String)
    case transactionFinished(productID: String, transactionID: UInt64, originalTransactionID: UInt64)
    case unfinishedTransactionFound(productID: String, transactionID: UInt64, originalTransactionID: UInt64)

    // Entitlements
    case entitlementsLoaded(productIDs: Set<String>)

    public var category: StoreLogCategory {
        switch self {
        case .fetchStarted, .fetchCompleted, .fetchFailed:
            return .productService
        case .purchaseStarted, .purchaseSucceeded, .purchaseCancelled, .purchasePending, .purchaseFailed:
            return .purchaseFlow
        case .transactionReceived, .transactionVerified, .transactionUnverified, .transactionFinished, .unfinishedTransactionFound:
            return .transactions
        case .entitlementsLoaded:
            return .entitlements
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
            return "\(prefix) Pending approval — \(productID)"
        case .purchaseFailed(let productID, let error):
            return "\(prefix) Failed — \(productID): \(error)"
        case .transactionReceived(let productID, let id, _):
            return "\(prefix) Received #\(id) — \(productID)"
        case .transactionVerified(let productID, let id, _):
            return "\(prefix) Verified #\(id) — \(productID)"
        case .transactionUnverified(let productID):
            return "\(prefix) Unverified — \(productID)"
        case .transactionFinished(let productID, let id, _):
            return "\(prefix) Finished #\(id) — \(productID)"
        case .unfinishedTransactionFound(let productID, let id, _):
            return "\(prefix) Unfinished #\(id) found — \(productID)"
        case .entitlementsLoaded(let productIDs):
            return "\(prefix) \(productIDs.isEmpty ? "No active entitlements" : productIDs.joined(separator: ", "))"
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
        case .purchaseFailed:              return "cart.badge.minus"
        case .transactionReceived:          return "arrow.left.circle"
        case .transactionVerified:          return "checkmark.seal.fill"
        case .transactionUnverified:        return "exclamationmark.shield.fill"
        case .transactionFinished:          return "flag.checkered"
        case .unfinishedTransactionFound:   return "exclamationmark.circle"
        case .entitlementsLoaded:           return "person.badge.shield.checkmark"
        }
    }

    public var searchableText: String {
        details.map { "\($0.label) \($0.value)" }.joined(separator: " ")
    }

    public var isError: Bool {
        switch self {
        case .fetchFailed, .transactionUnverified, .purchaseFailed: return true
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
             .purchaseCancelled(let productID),
             .purchasePending(let productID):
            return [Detail(label: "Product ID", value: productID)]
        case .purchaseFailed(let productID, let error):
            return [
                Detail(label: "Product ID", value: productID),
                Detail(label: "Error", value: error)
            ]
        case .transactionReceived(let productID, let id, let originalID),
             .transactionVerified(let productID, let id, let originalID),
             .transactionFinished(let productID, let id, let originalID),
             .unfinishedTransactionFound(let productID, let id, let originalID):
            return [
                Detail(label: "Transaction ID", value: "#\(id)"),
                Detail(label: "Original Txn ID", value: "#\(originalID)"),
                Detail(label: "Product ID", value: productID)
            ]
        case .transactionUnverified(let productID):
            return [
                Detail(label: "Product ID", value: productID),
                Detail(label: "Reason", value: "Signature verification failed")
            ]
        case .entitlementsLoaded(let productIDs):
            return [
                Detail(label: "Count", value: "\(productIDs.count)"),
                Detail(label: "Product IDs", value: productIDs.isEmpty ? "None" : productIDs.sorted().joined(separator: "\n"))
            ]
        }
    }
}

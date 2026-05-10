import StoreKit

public protocol Purchasable: Sendable {
    func purchase(product: StoreProduct, groupID: String?) async throws -> Product.PurchaseResult
}

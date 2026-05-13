import Combine
import StoreKit

public protocol Purchasable: Sendable {
    func purchase(
        product: StoreProduct,
        attributes: PurchaseAttributes
    ) async throws -> Product.PurchaseResult
    func purchasePublisher(product: StoreProduct, attributes: PurchaseAttributes) -> AnyPublisher<Product.PurchaseResult, Error>
}

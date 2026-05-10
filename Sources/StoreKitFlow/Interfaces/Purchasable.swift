import Combine
import StoreKit

public protocol Purchasable: Sendable {
    func purchase(product: StoreProduct) async throws -> Product.PurchaseResult
    func purchasePublisher(product: StoreProduct) -> AnyPublisher<Product.PurchaseResult, Error>
}

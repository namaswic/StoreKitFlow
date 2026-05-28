import Combine
import StoreKit

public protocol Purchasable: Sendable {
    func purchase(
        product: StoreProduct,
        attributes: PurchaseAttributes
    ) async throws -> Product.PurchaseResult
}

public extension Purchasable {
    func purchasePublisher(
        product: StoreProduct,
        attributes: PurchaseAttributes = PurchaseAttributes()
    ) -> AnyPublisher<Product.PurchaseResult, Error> {
        Future { promise in
            Task {
                do { promise(.success(try await self.purchase(product: product, attributes: attributes))) }
                catch { promise(.failure(error)) }
            }
        }
        .eraseToAnyPublisher()
    }
}

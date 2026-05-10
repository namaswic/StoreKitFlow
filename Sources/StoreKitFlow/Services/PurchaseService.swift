import Combine
import StoreKit

public final class PurchaseService: Purchasable {
    public init() {}

    public func purchase(product: StoreProduct) async throws -> Product.PurchaseResult {
        let products = try await Product.products(for: [product.id])
        guard let skProduct = products.first else {
            throw PurchaseError.productNotFound
        }
        return try await skProduct.purchase()
    }

    public func purchasePublisher(product: StoreProduct) -> AnyPublisher<Product.PurchaseResult, Error> {
        Future { promise in
            Task {
                do {
                    let products = try await Product.products(for: [product.id])
                    guard let skProduct = products.first else {
                        promise(.failure(PurchaseError.productNotFound))
                        return
                    }
                    let result = try await skProduct.purchase()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

public enum PurchaseError: Error {
    case productNotFound
}

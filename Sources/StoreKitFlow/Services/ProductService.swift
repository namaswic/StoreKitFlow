import Combine
import StoreKit

public final class ProductService: ProductFetchable {
    public init() {}

    public func fetchProducts(ids: [String]) async throws -> [StoreProduct] {
        let products = try await Product.products(for: ids)
        return products.map(StoreProduct.init)
    }

    public func fetchProductsPublisher(ids: [String]) -> AnyPublisher<[StoreProduct], Error> {
        Future { promise in
            Task {
                do {
                    let products = try await Product.products(for: ids)
                    promise(.success(products.map(StoreProduct.init)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

private extension StoreProduct {
    init(_ product: Product) {
        self.init(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice,
            price: product.price,
            type: ProductType(product.type)
        )
    }
}

private extension ProductType {
    init(_ type: Product.ProductType) {
        switch type {
        case .consumable:       self = .consumable
        case .nonConsumable:    self = .nonConsumable
        case .autoRenewable:    self = .autoRenewable
        default:                self = .nonRenewing
        }
    }
}

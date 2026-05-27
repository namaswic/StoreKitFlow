import Combine

public final class MockProductService: ProductFetchable {
    public let stubbedProducts: [StoreProduct]

    public init(products: [StoreProduct] = MockData.products) {
        self.stubbedProducts = products
    }

    public func fetchProducts(ids: [String]) async throws -> [StoreProduct] {
        stubbedProducts
    }

    public func fetchProductsPublisher(ids: [String]) -> AnyPublisher<[StoreProduct], Error> {
        Just(stubbedProducts)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

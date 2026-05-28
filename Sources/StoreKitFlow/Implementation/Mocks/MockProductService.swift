public final class MockProductService: ProductFetchable {
    public let stubbedProducts: [StoreProduct]

    public init(products: [StoreProduct] = MockData.products) {
        self.stubbedProducts = products
    }

    public func fetchProducts(ids: [String]) async throws -> [StoreProduct] {
        stubbedProducts.filter { ids.contains($0.id) }
    }
}

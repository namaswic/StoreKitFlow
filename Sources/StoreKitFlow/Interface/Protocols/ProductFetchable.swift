import Combine

public protocol ProductFetchable: Sendable {
    func fetchProducts(ids: [String]) async throws -> [StoreProduct]
    func fetchProductsPublisher(ids: [String]) -> AnyPublisher<[StoreProduct], Error>
}

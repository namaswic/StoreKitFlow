import Combine

public protocol ProductFetchable: Sendable {
    func fetchProducts(ids: [String]) async throws -> [StoreProduct]
}

public extension ProductFetchable {
    func fetchProductsPublisher(ids: [String]) -> AnyPublisher<[StoreProduct], Error> {
        Future { promise in
            Task {
                do { promise(.success(try await self.fetchProducts(ids: ids))) }
                catch { promise(.failure(error)) }
            }
        }
        .eraseToAnyPublisher()
    }
}

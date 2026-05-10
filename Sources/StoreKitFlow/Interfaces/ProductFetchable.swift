public protocol ProductFetchable: Sendable {
    func fetchProducts(ids: [String], groupID: String?) async throws -> [StoreProduct]
}

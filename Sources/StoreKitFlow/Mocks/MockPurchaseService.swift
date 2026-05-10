import Combine
import StoreKit

public final class MockPurchaseService: Purchasable {
    public let shouldFail: Bool

    public init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    public func purchase(product: StoreProduct) async throws -> Product.PurchaseResult {
        if shouldFail { throw MockError.purchaseFailed }
        return .userCancelled
    }

    public func purchasePublisher(product: StoreProduct) -> AnyPublisher<Product.PurchaseResult, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await self.purchase(product: product)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

public enum MockError: Error {
    case purchaseFailed
}

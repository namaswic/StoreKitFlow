import Combine
import StoreKit
@testable import StoreKitFlow

final class ConfigurableMockPurchaseService: Purchasable {
    enum Behaviour {
        case returnCancelled
        case returnPending
        case throwError(Error)
    }

    var behaviour: Behaviour

    init(behaviour: Behaviour = .returnCancelled) {
        self.behaviour = behaviour
    }

    func purchase(product: StoreProduct, attributes: PurchaseAttributes) async throws -> Product.PurchaseResult {
        switch behaviour {
        case .returnCancelled:       return .userCancelled
        case .returnPending:         return .pending
        case .throwError(let error): throw error
        }
    }

    func purchasePublisher(product: StoreProduct, attributes: PurchaseAttributes) -> AnyPublisher<Product.PurchaseResult, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await self.purchase(product: product, attributes: attributes)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}

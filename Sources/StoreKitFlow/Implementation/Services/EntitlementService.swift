import Combine
import StoreKit

public final class EntitlementService: EntitlementCheckable {
    public init() {}

    public func currentEntitlements() async -> Set<String> {
        var productIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            productIDs.insert(transaction.productID)
        }
        return productIDs
    }

    public func isEligibleForIntroOffer(productID: String) async -> Bool {
        guard let products = try? await Product.products(for: [productID]),
              let product = products.first,
              let subscription = product.subscription else {
            return false
        }
        return await subscription.isEligibleForIntroOffer
    }

    public func currentEntitlementsPublisher() -> AnyPublisher<Set<String>, Never> {
        Future { promise in
            Task {
                let entitlements = await self.currentEntitlements()
                promise(.success(entitlements))
            }
        }
        .eraseToAnyPublisher()
    }

    public func isEligibleForIntroOfferPublisher(productID: String) -> AnyPublisher<Bool, Never> {
        Future { promise in
            Task {
                let eligible = await self.isEligibleForIntroOffer(productID: productID)
                promise(.success(eligible))
            }
        }
        .eraseToAnyPublisher()
    }
}

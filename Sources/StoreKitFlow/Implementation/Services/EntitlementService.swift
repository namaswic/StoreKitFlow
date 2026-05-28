import StoreKit

public final class EntitlementService: EntitlementCheckable, IntroOfferCheckable {
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
}

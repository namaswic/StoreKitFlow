import StoreKit

public final class PurchaseService: Purchasable {
    public init() {}

    public func purchase(
        product: StoreProduct,
        attributes: PurchaseAttributes = PurchaseAttributes()
    ) async throws -> Product.PurchaseResult {
        let products = try await Product.products(for: [product.id])
        guard let skProduct = products.first else {
            throw StoreKitFlowError.productNotFound
        }
        var options = attributes.toPurchaseOptions()

        if #available(iOS 18.0, macOS 15.0, *), let offerID = attributes.winBackOfferID, !offerID.isEmpty {
            if let offer = skProduct.subscription?.winBackOffers.first(where: { $0.id == offerID }) {
                options.insert(.winBackOffer(offer))
            }
        }

        if let jws = attributes.introductoryOfferJWS, !jws.isEmpty {
            options.insert(.introductoryOfferEligibility(compactJWS: jws))
        }

        return try await skProduct.purchase(options: options)
    }
}

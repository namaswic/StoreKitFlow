import Foundation

public struct StoreProduct: Identifiable, Sendable, Hashable {
    public let id: String
    public let displayName: String
    public let description: String
    public let displayPrice: String
    public let price: Decimal
    public let type: ProductType
    public let familyShareable: Bool
    public let introductoryOffer: IntroductoryOffer?
    public let promotionalOffers: [PromotionalOffer]
    public let winBackOffers: [WinBackOffer]

    public init(
        id: String,
        displayName: String,
        description: String,
        displayPrice: String,
        price: Decimal,
        type: ProductType,
        familyShareable: Bool = false,
        introductoryOffer: IntroductoryOffer? = nil,
        promotionalOffers: [PromotionalOffer] = [],
        winBackOffers: [WinBackOffer] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
        self.price = price
        self.type = type
        self.familyShareable = familyShareable
        self.introductoryOffer = introductoryOffer
        self.promotionalOffers = promotionalOffers
        self.winBackOffers = winBackOffers
    }
}

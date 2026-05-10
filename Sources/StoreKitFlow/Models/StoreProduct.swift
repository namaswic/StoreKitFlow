import Foundation

public struct StoreProduct: Identifiable, Sendable, Hashable {
    public let id: String
    public let displayName: String
    public let description: String
    public let displayPrice: String
    public let price: Decimal
    public let type: ProductType

    public init(
        id: String,
        displayName: String,
        description: String,
        displayPrice: String,
        price: Decimal,
        type: ProductType
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
        self.price = price
        self.type = type
    }
}

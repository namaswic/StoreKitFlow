public struct PromotionalOffer: Sendable, Hashable {
    public let id: String
    public let displayName: String
    public let paymentMode: PaymentMode
    public let displayPrice: String
    public let period: String

    public init(id: String, displayName: String, paymentMode: PaymentMode, displayPrice: String, period: String) {
        self.id = id
        self.displayName = displayName
        self.paymentMode = paymentMode
        self.displayPrice = displayPrice
        self.period = period
    }
}

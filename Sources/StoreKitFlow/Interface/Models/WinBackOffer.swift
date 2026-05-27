public struct WinBackOffer: Sendable, Hashable {
    public let id: String
    public let paymentMode: PaymentMode
    public let displayPrice: String
    public let period: String

    public init(id: String, paymentMode: PaymentMode, displayPrice: String, period: String) {
        self.id = id
        self.paymentMode = paymentMode
        self.displayPrice = displayPrice
        self.period = period
    }
}

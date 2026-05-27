public struct IntroductoryOffer: Sendable, Hashable {
    public let paymentMode: PaymentMode
    public let displayPrice: String
    public let period: String

    public init(paymentMode: PaymentMode, displayPrice: String, period: String) {
        self.paymentMode = paymentMode
        self.displayPrice = displayPrice
        self.period = period
    }
}

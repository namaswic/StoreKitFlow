import StoreKitFlow

struct DisplayOffer {
    let title: String
    let paymentMode: PaymentMode
    let displayPrice: String
    let period: String
}

extension IntroductoryOffer {
    var asDisplayOffer: DisplayOffer {
        DisplayOffer(title: "Intro Offer", paymentMode: paymentMode, displayPrice: displayPrice, period: period)
    }
}

extension PromotionalOffer {
    var asDisplayOffer: DisplayOffer {
        DisplayOffer(title: displayName.isEmpty ? id : displayName, paymentMode: paymentMode, displayPrice: displayPrice, period: period)
    }
}

extension WinBackOffer {
    var asDisplayOffer: DisplayOffer {
        DisplayOffer(title: id, paymentMode: paymentMode, displayPrice: displayPrice, period: period)
    }
}

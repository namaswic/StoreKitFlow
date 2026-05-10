import SwiftUI
import StoreKitFlow

struct OfferSectionView: View {
    let title: String
    let offers: [DisplayOffer]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            ForEach(offers, id: \.title) { offer in
                OfferRowView(offer: offer)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OfferSectionView(
        title: "Introductory Offer",
        offers: [
            DisplayOffer(
                title: "Free Trial",
                paymentMode: .free,
                displayPrice: "$0.00",
                period: "P1W"
            ),
            DisplayOffer(
                title: "Pay as you go",
                paymentMode: .payAsYouGo,
                displayPrice: "$1.99",
                period: "P1M"
            ),
            DisplayOffer(
                title: "Pay up front",
                paymentMode: .payUpFront,
                displayPrice: "$4.99",
                period: "P3M"
            )
        ]
    )
    .padding()
}

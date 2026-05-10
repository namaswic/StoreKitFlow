import SwiftUI
import StoreKitFlow

struct OfferRowView: View {
    let offer: DisplayOffer

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(offer.title)
                    .font(.subheadline)
                    .bold()
                Text(offer.period)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(offer.paymentMode.displayName)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(offer.paymentMode.color, in: Capsule())
                Text(offer.paymentMode == .free ? "Free" : offer.displayPrice)
                    .font(.subheadline)
                    .bold()
            }
        }
        .padding(.vertical, 4)
    }
}

private extension PaymentMode {
    var displayName: String {
        switch self {
        case .free:         return "Free Trial"
        case .payAsYouGo:   return "Pay as you go"
        case .payUpFront:   return "Pay up front"
        }
    }

    var color: Color {
        switch self {
        case .free:         return .green
        case .payAsYouGo:   return .blue
        case .payUpFront:   return .purple
        }
    }
}

#Preview {
    List {
        OfferRowView(offer: DisplayOffer(title: "Free Trial", paymentMode: .free, displayPrice: "$0.00", period: "1 Week"))
        OfferRowView(offer: DisplayOffer(title: "Pay as you go", paymentMode: .payAsYouGo, displayPrice: "$1.99", period: "3 Months"))
        OfferRowView(offer: DisplayOffer(title: "Pay up front", paymentMode: .payUpFront, displayPrice: "$4.99", period: "3 Months"))
    }
}

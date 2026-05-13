import SwiftUI

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

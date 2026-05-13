import SwiftUI

struct ProductDetailScreen: View {
    let product: StoreProduct
    @EnvironmentObject private var store: StoreKitFlowStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ProductHeaderView(product: product)
                ProductTypeInfoView(product: product)
                if let intro = product.introductoryOffer {
                    OfferSectionView(title: "Introductory Offer", offers: [intro.asDisplayOffer])
                }
                if !product.promotionalOffers.isEmpty {
                    OfferSectionView(title: "Promotional Offers", offers: product.promotionalOffers.map(\.asDisplayOffer))
                }
                if !product.winBackOffers.isEmpty {
                    OfferSectionView(title: "Win-Back Offers", offers: product.winBackOffers.map(\.asDisplayOffer))
                }
                ProductFamilySharingView(familyShareable: product.familyShareable)
            }
            .padding()
        }
        .navigationTitle(product.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if store.isPurchased(product) {
                    Label("Purchased", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
        }
    }
}

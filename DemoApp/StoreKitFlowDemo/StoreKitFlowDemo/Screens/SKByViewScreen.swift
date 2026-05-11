import SwiftUI

struct SKByViewScreen: View {
    var body: some View {
        NavigationStack {
            List {
                viewRow(
                    title: "ProductView",
                    description: "A single product row with a buy button. Supports three styles, custom icons, and declarative product loading.",
                    chips: ["productViewStyle", "productIconBorder", "storeProductTask"],
                    icon: "cube.box.fill",
                    color: .blue,
                    destination: SKProductViewScreen()
                )
                viewRow(
                    title: "StoreView",
                    description: "A list of multiple products with buy buttons. Supports all ProductView styles and accessory buttons.",
                    chips: ["productViewStyle", "productIconBorder", "storeButton"],
                    icon: "bag.fill",
                    color: .indigo,
                    destination: SKStoreViewScreen()
                )
                viewRow(
                    title: "SubscriptionStoreView",
                    description: "A full subscription paywall — control style, background, button labels, custom controls, accessory buttons, and live status binding.",
                    chips: ["subscriptionStoreControlStyle", "subscriptionStoreButtonLabel", "containerBackground", "subscriptionStatusTask", "+more"],
                    icon: "repeat.circle.fill",
                    color: .purple,
                    destination: SKSubscriptionStoreViewScreen()
                )
                viewRow(
                    title: "SubscriptionOfferView",
                    description: "Presents intro, promo, or win-back offers for a subscription group. Supports compact and automatic layout styles.",
                    chips: ["subscriptionOfferViewStyle", "visibleRelationship"],
                    icon: "tag.fill",
                    color: .orange,
                    destination: SKSubscriptionOfferViewScreen()
                )
            }
            .navigationTitle("By View")
        }
    }

    private func viewRow<D: View>(title: String, description: String, chips: [String], icon: String, color: Color, destination: D) -> some View {
        NavigationLink(destination: destination) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                    FlowLayout(spacing: 4) {
                        ForEach(chips, id: \.self) { chip in
                            Text(chip)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
}

#Preview {
    SKByViewScreen()
}

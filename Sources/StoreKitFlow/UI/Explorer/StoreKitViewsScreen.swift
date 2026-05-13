import SwiftUI

struct StoreKitViewsScreen: View {
    var body: some View {
        NavigationStack {
            List {
                categoryRow(
                    title: "Views",
                    description: "Apple's native StoreKit views for merchandising products and subscriptions — ready to drop into any app.",
                    types: ["ProductView", "StoreView", "SubscriptionStoreView", "SubscriptionOfferView"],
                    icon: "rectangle.stack.fill",
                    color: .blue,
                    destination: SKViewsDemoScreen()
                )
                categoryRow(
                    title: "Controls",
                    description: "Building blocks for fully custom subscription plan selectors — compose your own picker and button layout.",
                    types: ["SubscriptionStorePicker", "SubscriptionStoreButton", "SubscriptionStorePickerOption"],
                    icon: "slider.horizontal.3",
                    color: .purple,
                    destination: SKControlsDemoScreen()
                )
                categoryRow(
                    title: "Styling",
                    description: "Modifiers that control how products and subscription controls look — style, background, button labels, and icon borders.",
                    types: ["productViewStyle", "subscriptionStoreControlStyle", "subscriptionStoreControlBackground", "subscriptionStoreButtonLabel", "productIconBorder"],
                    icon: "paintbrush.fill",
                    color: .orange,
                    destination: SKStylingDemoScreen()
                )
                categoryRow(
                    title: "Data Binding",
                    description: "Declarative view modifiers that load product metadata and observe live subscription status without manual async code.",
                    types: ["storeProductTask", "subscriptionStatusTask"],
                    icon: "bolt.fill",
                    color: .green,
                    destination: SKDataBindingDemoScreen()
                )
                categoryRow(
                    title: "Structure",
                    description: "Layout types that group subscription options by period or category — compose multi-section plan selectors.",
                    types: ["SubscriptionOptionGroup", "SubscriptionOptionGroupSet", "SubscriptionPeriodGroupSet", "SubscriptionOptionSection"],
                    icon: "rectangle.3.group.fill",
                    color: .teal,
                    destination: SKStructureDemoScreen()
                )
                categoryRow(
                    title: "Composition",
                    description: "Declarative building blocks for constructing fully custom store layouts with fine-grained product and section control.",
                    types: ["StoreContent", "StoreContentBuilder"],
                    icon: "square.stack.3d.up.fill",
                    color: .indigo,
                    destination: SKCompositionDemoScreen()
                )
            }
            .navigationTitle("StoreKit Explorer")
        }
    }

    private func categoryRow<D: View>(title: String, description: String, types: [String], icon: String, color: Color, destination: D) -> some View {
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
                    typeChips(types, color: color)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func typeChips(_ types: [String], color: Color) -> some View {
        FlowLayout(spacing: 4) {
            ForEach(types, id: \.self) { type in
                Text(type)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}

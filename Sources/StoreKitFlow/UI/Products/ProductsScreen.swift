import SwiftUI

struct ProductsScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore

    private var sections: [(title: String, products: [StoreProduct])] {
        let order: [ProductType] = [.consumable, .nonConsumable, .autoRenewable, .nonRenewing]
        return order.compactMap { type in
            let products = store.products.filter { $0.type == type }
            guard !products.isEmpty else { return nil }
            return (title: type.sectionTitle, products: products)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("Loading products…")
                } else if store.products.isEmpty {
                    ContentUnavailableView(
                        "No Products",
                        systemImage: "bag.badge.questionmark",
                        description: Text("No products found. Check your StoreKit configuration.")
                    )
                } else {
                    List {
                        ForEach(sections, id: \.title) { section in
                            Section(section.title) {
                                ForEach(section.products) { product in
                                    ProductRow(product: product)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Products")
        }
    }
}

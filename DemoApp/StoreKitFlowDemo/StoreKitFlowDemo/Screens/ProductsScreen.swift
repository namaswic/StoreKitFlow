import SwiftUI
import StoreKitFlow

struct ProductsScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore

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
                    List(store.products) { product in
                        ProductRow(product: product)
                    }
                }
            }
            .navigationTitle("Products")
        }
    }
}

#Preview {
    ProductsScreen()
        .environmentObject(StoreKitFlowStore(
            productService: MockProductService(),
            entitlementService: MockEntitlementService(),
            transactionService: MockTransactionService()
        ))
}

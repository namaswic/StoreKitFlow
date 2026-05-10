import SwiftUI
import StoreKitFlow

struct ProductRow: View {
    let product: StoreProduct
    @EnvironmentObject private var store: StoreKitFlowStore

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if store.isPurchased(product) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Text(product.displayPrice)
                    .font(.subheadline)
                    .bold()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let store = StoreKitFlowStore(
        productService: MockProductService(),
        entitlementService: MockEntitlementService(),
        transactionService: MockTransactionService()
    )
    return List {
        ProductRow(product: StoreProduct(
            id: "com.storekitflow.demo.pro.monthly",
            displayName: "Pro Monthly",
            description: "Full access, billed monthly.",
            displayPrice: "$4.99",
            price: 4.99,
            type: .autoRenewable
        ))
    }
    .environmentObject(store)
}

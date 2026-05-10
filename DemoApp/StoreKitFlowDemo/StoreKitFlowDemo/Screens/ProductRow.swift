import SwiftUI
import StoreKitFlow

struct ProductRow: View {
    let product: StoreProduct
    @EnvironmentObject private var store: StoreKitFlowStore

    var body: some View {
        NavigationLink(destination: ProductDetailScreen(product: product)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
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
}

#Preview {
    NavigationStack {
        List {
            ProductRow(product: MockData.products[4])
        }
        .environmentObject(StoreKitFlowStore(
            productService: MockProductService(),
            entitlementService: MockEntitlementService(),
            transactionService: MockTransactionService()
        ))
    }
}

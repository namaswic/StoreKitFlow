import SwiftUI
import StoreKitFlow

struct ProductRow: View {
    let product: StoreProduct
    @EnvironmentObject private var store: StoreKitFlowStore

    var body: some View {
        HStack(spacing: 12) {
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
                    .font(.title3)
            } else {
                Button {
                    Task { await store.purchase(product) }
                } label: {
                    Text(product.displayPrice)
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(store.isPurchasing)
            }
            NavigationLink(destination: ProductDetailScreen(product: product)) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .frame(width: 28)
        }
        .padding(.vertical, 4)
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

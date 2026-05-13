import SwiftUI

struct ProductHeaderView: View {
    let product: StoreProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(product.displayName)
                    .font(.title2)
                    .bold()
                Spacer()
                Text(product.displayPrice)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.blue)
            }
            Text(product.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

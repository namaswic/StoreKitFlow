import SwiftUI

struct InfoRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        InfoRow(
            icon: "gift.fill",
            color: .green,
            title: "Free Trial",
            description: "User gets full access for a period at no charge. Billing starts automatically after the trial ends if they don't cancel."
        )
        InfoRow(
            icon: "arrow.uturn.backward.circle.fill",
            color: .red,
            title: "Win-Back Offer",
            description: "A special deal shown automatically to lapsed subscribers in the App Store. Apple decides who sees it based on their subscription history."
        )
    }
}

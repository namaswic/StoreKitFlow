import SwiftUI
import StoreKitFlow

struct ProductTypeInfoView: View {
    let product: StoreProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(product.type.displayName, systemImage: product.type.systemImage)
                .font(.headline)
            Text(product.type.realWorldExample)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(product.type.useCaseDescription)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private extension ProductType {
    var displayName: String {
        switch self {
        case .consumable:       return "Consumable"
        case .nonConsumable:    return "Non-Consumable"
        case .autoRenewable:    return "Auto-Renewable Subscription"
        case .nonRenewing:      return "Non-Renewing Subscription"
        }
    }

    var systemImage: String {
        switch self {
        case .consumable:       return "cart.fill"
        case .nonConsumable:    return "lock.open.fill"
        case .autoRenewable:    return "arrow.clockwise.circle.fill"
        case .nonRenewing:      return "calendar.badge.clock"
        }
    }

    var realWorldExample: String {
        switch self {
        case .consumable:
            return "Used by: Clash of Clans (gems), Duolingo (streaks), Twitter/X (Boost credits)"
        case .nonConsumable:
            return "Used by: Darkroom (filters pack), Pockity (lifetime license), Reeder (one-time unlock)"
        case .autoRenewable:
            return "Used by: Spotify, Notion, Linear, Figma, Bear, Fantastical"
        case .nonRenewing:
            return "Used by: news apps (30-day access pass), sports apps (season pass), event apps (conference access)"
        }
    }

    var useCaseDescription: String {
        switch self {
        case .consumable:
            return "Perfect for in-game currency, credits, or any resource that depletes and can be repurchased."
        case .nonConsumable:
            return "Perfect for permanent unlocks, lifetime licenses, or one-time feature purchases."
        case .autoRenewable:
            return "Perfect for SaaS tools, media streaming, productivity apps — anything with ongoing value."
        case .nonRenewing:
            return "Perfect for time-limited access without auto-renewal — seasonal content, event passes, or trials."
        }
    }
}

#Preview {
    ProductTypeInfoView(product: MockData.products[4])
        .padding()
}

import SwiftUI

struct InfoScreen: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Product Types") {
                    InfoRow(
                        icon: "cart.fill",
                        color: .orange,
                        title: "Consumable",
                        description: "Bought and used up. Can be purchased again. Think coins, credits, or lives in a game."
                    )
                    InfoRow(
                        icon: "lock.open.fill",
                        color: .blue,
                        title: "Non-Consumable",
                        description: "Bought once, yours forever. Think removing ads or unlocking a premium theme."
                    )
                    InfoRow(
                        icon: "arrow.clockwise.circle.fill",
                        color: .green,
                        title: "Auto-Renewable Subscription",
                        description: "Charges the user on a recurring basis (monthly, yearly) until they cancel. Most common for apps like Spotify or Notion."
                    )
                    InfoRow(
                        icon: "calendar.badge.clock",
                        color: .purple,
                        title: "Non-Renewing Subscription",
                        description: "Gives access for a fixed period but does NOT auto-renew. The user must repurchase manually. Good for seasonal passes."
                    )
                }

                Section("Offer Types") {
                    InfoRow(
                        icon: "tag.fill",
                        color: .green,
                        title: "Introductory Offer",
                        description: "A special deal shown to new subscribers only — once per product group. Examples: '7 days free', 'first 3 months for $0.99'."
                    )
                    InfoRow(
                        icon: "person.badge.plus",
                        color: .blue,
                        title: "Promotional Offer",
                        description: "A deal you offer to existing or past subscribers. Your server decides who gets it. Good for upgrade incentives or loyalty rewards."
                    )
                    InfoRow(
                        icon: "envelope.open.fill",
                        color: .orange,
                        title: "Offer Code",
                        description: "A redeemable code (like a coupon) you distribute to users — via email, social media, or support. Apple validates and applies it."
                    )
                    InfoRow(
                        icon: "arrow.uturn.backward.circle.fill",
                        color: .red,
                        title: "Win-Back Offer",
                        description: "A special deal shown automatically to lapsed subscribers in the App Store. Apple decides who sees it based on their subscription history."
                    )
                }

                Section("Payment Modes") {
                    InfoRow(
                        icon: "gift.fill",
                        color: .green,
                        title: "Free Trial",
                        description: "User gets full access for a period at no charge. Billing starts automatically after the trial ends if they don't cancel."
                    )
                    InfoRow(
                        icon: "calendar",
                        color: .blue,
                        title: "Pay as you go",
                        description: "User pays a reduced price for each period during the offer. Example: $0.99/month for 3 months, then full price."
                    )
                    InfoRow(
                        icon: "creditcard.fill",
                        color: .purple,
                        title: "Pay up front",
                        description: "User pays a single reduced amount upfront for the entire offer period. Example: $4.99 for 3 months (instead of $14.97)."
                    )
                }

                Section("Other Concepts") {
                    InfoRow(
                        icon: "person.3.fill",
                        color: .teal,
                        title: "Family Sharing",
                        description: "When enabled, one family member's purchase is shared with up to 5 others in their Family Sharing group at no extra cost."
                    )
                    InfoRow(
                        icon: "checkmark.seal.fill",
                        color: .green,
                        title: "Entitlement",
                        description: "Proof that a user has access to a product. StoreKit 2 lets you check current entitlements to unlock features without a server."
                    )
                    InfoRow(
                        icon: "arrow.triangle.2.circlepath",
                        color: .gray,
                        title: "Transaction",
                        description: "A record of every purchase. StoreKit 2 provides cryptographically signed transactions you verify locally — no receipt validation server needed."
                    )
                }
            }
            .navigationTitle("StoreKit Guide")
        }
    }
}

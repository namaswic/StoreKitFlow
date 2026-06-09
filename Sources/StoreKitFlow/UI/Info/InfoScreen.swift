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

                Section("Subscription Groups") {
                    InfoRow(
                        icon: "rectangle.3.group.fill",
                        color: .indigo,
                        title: "What is a Subscription Group?",
                        description: "A collection of subscription products a user can only hold one of at a time. Monthly and yearly plans for the same app belong in one group — Apple enforces mutual exclusivity."
                    )
                    InfoRow(
                        icon: "arrow.up.circle.fill",
                        color: .green,
                        title: "Upgrades",
                        description: "Moving to a higher-tier or longer-duration plan within the same group. Apple prorates the remaining value and charges the difference immediately."
                    )
                    InfoRow(
                        icon: "arrow.down.circle.fill",
                        color: .orange,
                        title: "Downgrades",
                        description: "Moving to a lower-tier plan within the same group. The change takes effect at the next renewal — the user keeps their current tier until then."
                    )
                    InfoRow(
                        icon: "arrow.left.arrow.right.circle.fill",
                        color: .blue,
                        title: "Cross-grade",
                        description: "Moving between plans of equal value (e.g. monthly ↔ yearly at the same price tier). May take effect immediately or at renewal depending on Apple's rules."
                    )
                }

                Section("Transaction Lifecycle") {
                    InfoRow(
                        icon: "flag.checkered",
                        color: .green,
                        title: "Why call finish()?",
                        description: "StoreKit re-delivers unfinished transactions on every app launch until finish() is called. Finishing tells Apple the app has processed the purchase and removes it from the queue. Forgetting to call it causes duplicate deliveries and the silent re-subscribe bug."
                    )
                    InfoRow(
                        icon: "clock.badge.exclamationmark.fill",
                        color: .orange,
                        title: "Pending",
                        description: "A purchase that needs external approval before it completes — Ask to Buy (parental approval), billing failure (expired card), or Family Sharing organiser approval. Never grant access for a pending transaction. The result arrives via Transaction.updates when resolved."
                    )
                    InfoRow(
                        icon: "exclamationmark.shield.fill",
                        color: .red,
                        title: "Unverified",
                        description: "A transaction that failed StoreKit's local cryptographic check. This can indicate tampering or a StoreKit bug. Never grant access, never call finish() — discard it."
                    )
                    InfoRow(
                        icon: "arrow.counterclockwise.circle.fill",
                        color: .purple,
                        title: "Missed Renewal",
                        description: "A subscription that renewed while the app was backgrounded and the process was killed before finish() ran. StoreKit has no record of this on device. StoreKitFlow's reconciliation pass detects and recovers these on next launch."
                    )
                }

                Section("Refunds & Revocations") {
                    InfoRow(
                        icon: "arrow.uturn.left.circle.fill",
                        color: .red,
                        title: "Refund",
                        description: "When Apple grants a refund, StoreKit delivers a revocation event via Transaction.updates. The transaction's revocationDate becomes non-nil. Revoke access immediately — the user has been reimbursed."
                    )
                    InfoRow(
                        icon: "person.badge.minus",
                        color: .orange,
                        title: "Family Sharing Revocation",
                        description: "If a family member leaves the group or the purchaser cancels, shared access is revoked. StoreKit delivers a revocation event. Handle it the same way as a refund revocation."
                    )
                    InfoRow(
                        icon: "nosign",
                        color: .gray,
                        title: "Revocation vs Cancellation",
                        description: "Cancellation means a subscription won't renew — the user keeps access until the current period ends. Revocation means access is cut off immediately, usually because of a refund. They require different responses in your app."
                    )
                }

                Section("Storefront & Region") {
                    InfoRow(
                        icon: "globe",
                        color: .blue,
                        title: "Storefront",
                        description: "The App Store region the user is currently signed into. Prices are set per storefront in App Store Connect — the same product can have different prices in different countries."
                    )
                    InfoRow(
                        icon: "purchased.circle.fill",
                        color: .teal,
                        title: "Product Availability",
                        description: "Products can be made available in all territories or a custom subset. If a product isn't available in the user's storefront, Product.products(for:) returns an empty array for that ID."
                    )
                    InfoRow(
                        icon: "arrow.triangle.swap",
                        color: .indigo,
                        title: "Storefront Changes",
                        description: "Users can change their storefront mid-session (e.g. switching Apple IDs). The onStorefrontChange purchase option lets you intercept this and cancel or continue the purchase."
                    )
                }

                Section("Testing Environments") {
                    InfoRow(
                        icon: "laptopcomputer",
                        color: .gray,
                        title: "Xcode / Simulator",
                        description: "Uses a local StoreKit test server — no network, no Apple ID. Transactions return instantly. Renewals run on a 1–2 minute cycle. environment value: \"Xcode\"."
                    )
                    InfoRow(
                        icon: "testtube.2",
                        color: .orange,
                        title: "Sandbox",
                        description: "Real Apple servers with free test purchases. Renewals run on an accelerated schedule (~5 min/month, max 6 renewals). Requires a sandbox Apple ID. environment value: \"Sandbox\"."
                    )
                    InfoRow(
                        icon: "storefront.fill",
                        color: .green,
                        title: "Production",
                        description: "Real App Store, real money. Renewals follow the actual calendar. Win-back offers and all offer types work reliably here. environment value: \"Production\"."
                    )
                    InfoRow(
                        icon: "exclamationmark.circle",
                        color: .yellow,
                        title: "Sandbox Limitations",
                        description: "Win-back offers are inconsistent in sandbox. Introductory offer eligibility resets after expiry (not realistic). AppStore.sync() may prompt a sign-in sheet. Always validate your final offer flows in a production TestFlight build."
                    )
                }
            }
            .navigationTitle("StoreKit Guide")
        }
    }
}

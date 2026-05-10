public enum MockData {
    public static let products: [StoreProduct] = [
        // Consumables
        StoreProduct(
            id: "com.storekitflow.demo.coins10",
            displayName: "10 Coins",
            description: "A pack of 10 coins. Use coins to unlock bonus content, skip wait times, or boost your progress in the app.",
            displayPrice: "$0.99",
            price: 0.99,
            type: .consumable
        ),
        // Non-Consumables
        StoreProduct(
            id: "com.storekitflow.demo.removeads",
            displayName: "Remove Ads",
            description: "Permanently remove all banner and interstitial ads across the entire app. One-time purchase, no expiry.",
            displayPrice: "$2.99",
            price: 2.99,
            type: .nonConsumable
        ),
        StoreProduct(
            id: "com.storekitflow.demo.themes",
            displayName: "Unlock Themes",
            description: "Unlock all 12 premium themes including Dark Mode Pro, Sunset, Ocean, and Midnight. One-time purchase, applies to all devices.",
            displayPrice: "$1.99",
            price: 1.99,
            type: .nonConsumable
        ),
        // Auto-Renewable — Pro group
        StoreProduct(
            id: "com.storekitflow.demo.pro.monthly",
            displayName: "Pro Monthly",
            description: "Unlimited projects, advanced analytics, priority support, and early access to new features. Billed monthly, cancel anytime.",
            displayPrice: "$4.99",
            price: 4.99,
            type: .autoRenewable
        ),
        StoreProduct(
            id: "com.storekitflow.demo.pro.yearly",
            displayName: "Pro Yearly",
            description: "Unlimited projects, advanced analytics, priority support, and early access to new features. Billed yearly — save 33% vs monthly.",
            displayPrice: "$39.99",
            price: 39.99,
            type: .autoRenewable
        ),
        StoreProduct(
            id: "com.storekitflow.demo.pro.monthly.upfront",
            displayName: "Pro Monthly — Upfront Deal",
            description: "Same Pro features, paid 3 months upfront. Lock in your rate and save vs paying month to month.",
            displayPrice: "$4.99",
            price: 4.99,
            type: .autoRenewable
        ),
        // Auto-Renewable — Basic group
        StoreProduct(
            id: "com.storekitflow.demo.basic.monthly",
            displayName: "Basic Monthly",
            description: "Access core features including analytics dashboard, up to 5 projects, and email support. Billed monthly, cancel anytime.",
            displayPrice: "$1.99",
            price: 1.99,
            type: .autoRenewable
        ),
        StoreProduct(
            id: "com.storekitflow.demo.basic.yearly",
            displayName: "Basic Yearly",
            description: "Access core features including analytics dashboard, up to 5 projects, and email support. Billed yearly — save 37% vs monthly.",
            displayPrice: "$14.99",
            price: 14.99,
            type: .autoRenewable
        ),
        // Non-Renewing
        StoreProduct(
            id: "com.storekitflow.demo.pass.30days",
            displayName: "30-Day Pass",
            description: "Full Pro access for 30 days. Great for short-term projects or trying out Pro features before committing to a subscription.",
            displayPrice: "$0.99",
            price: 0.99,
            type: .nonRenewing
        )
    ]
}

import StoreKit

/// Optional parameters you can attach to a purchase.
///
/// Pass this to `StoreKitFlowStore.purchase(_:attributes:)`. All fields are optional —
/// only set what you need:
///
/// ```swift
/// // Link the purchase to a user account in your backend
/// await store.purchase(product, attributes: .init(appAccountToken: currentUser.id))
///
/// // Buy multiple consumables in one transaction
/// await store.purchase(product, attributes: .init(quantity: 5))
///
/// // Tag the purchase with server-readable metadata
/// await store.purchase(product, attributes: .init(customValues: ["campaign": "summer24"]))
/// ```
public struct PurchaseAttributes {
    /// A UUID that links this purchase to an account in your system.
    /// Persists on the resulting `Transaction` so your server can verify ownership.
    /// Use this when users are signed into your backend.
    public var appAccountToken: UUID?

    /// Number of units to purchase in a single transaction.
    /// Only valid for consumables and non-renewing subscriptions — ignored for auto-renewable subscriptions.
    public var quantity: Int?

    /// The `id` of a `SubscriptionOffer` of type `.promotional` to apply.
    /// Requires a matching server-signed offer configured in App Store Connect.
    /// Leave `nil` if no promotional offer should be applied.
    public var promotionalOfferID: String?

    /// When `true`, simulates Ask to Buy in the Sandbox environment so you can test
    /// parental-approval flows without a real Family Sharing setup.
    /// Has no effect in production.
    public var simulatesAskToBuy: Bool?

    /// Arbitrary string key-value pairs forwarded to your server via the transaction's
    /// `appTransactionID` or verified receipt. Useful for attribution, A/B test variants,
    /// or campaign tracking. Keys and values must both be `String`.
    public var customValues: [String: String] = [:]

    public init(
        appAccountToken: UUID? = nil,
        quantity: Int? = nil,
        promotionalOfferID: String? = nil,
        simulatesAskToBuy: Bool? = nil,
        customValues: [String: String] = [:]
    ) {
        self.appAccountToken = appAccountToken
        self.quantity = quantity
        self.promotionalOfferID = promotionalOfferID
        self.simulatesAskToBuy = simulatesAskToBuy
        self.customValues = customValues
    }

    func toPurchaseOptions() -> Set<Product.PurchaseOption> {
        var options: Set<Product.PurchaseOption> = []
        if let token = appAccountToken {
            options.insert(.appAccountToken(token))
        }
        if let qty = quantity {
            options.insert(.quantity(qty))
        }
        if let simulate = simulatesAskToBuy {
            options.insert(.simulatesAskToBuyInSandbox(simulate))
        }
        for (key, value) in customValues {
            options.insert(.custom(key: key, value: value))
        }
        return options
    }
}

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
/// await store.purchase(product, attributes: .init(customStringValues: ["campaign": "summer24"]))
/// ```
public struct PurchaseAttributes: Sendable {
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

    /// Arbitrary string key-value pairs forwarded via `Product.PurchaseOption.custom(key:value:)`.
    public var customStringValues: [String: String] = [:]

    /// Arbitrary double key-value pairs forwarded via `Product.PurchaseOption.custom(key:value:)`.
    public var customDoubleValues: [String: Double] = [:]

    /// Arbitrary bool key-value pairs forwarded via `Product.PurchaseOption.custom(key:value:)`.
    public var customBoolValues: [String: Bool] = [:]

    /// The ID of a win-back offer to apply. Resolved to a `Product.SubscriptionOffer` in `PurchaseService`.
    /// Only available on iOS 18+ / macOS 15+.
    public var winBackOfferID: String?

    /// When `true`, inserts a no-op `.onStorefrontChange` handler. The real handler should be
    /// registered at the app level — this is for testing the option is plumbed correctly.
    public var onStorefrontChange: Bool = false

    /// A compact JWS string for introductory offer eligibility verification.
    /// Obtained from your server after verifying the user qualifies.
    public var introductoryOfferJWS: String?

    public init(
        appAccountToken: UUID? = nil,
        quantity: Int? = nil,
        promotionalOfferID: String? = nil,
        simulatesAskToBuy: Bool? = nil,
        customStringValues: [String: String] = [:],
        customDoubleValues: [String: Double] = [:],
        customBoolValues: [String: Bool] = [:],
        winBackOfferID: String? = nil,
        onStorefrontChange: Bool = false,
        introductoryOfferJWS: String? = nil
    ) {
        self.appAccountToken = appAccountToken
        self.quantity = quantity
        self.promotionalOfferID = promotionalOfferID
        self.simulatesAskToBuy = simulatesAskToBuy
        self.customStringValues = customStringValues
        self.customDoubleValues = customDoubleValues
        self.customBoolValues = customBoolValues
        self.winBackOfferID = winBackOfferID
        self.onStorefrontChange = onStorefrontChange
        self.introductoryOfferJWS = introductoryOfferJWS
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
        for (key, value) in customStringValues {
            options.insert(.custom(key: key, value: value))
        }
        for (key, value) in customDoubleValues {
            options.insert(.custom(key: key, value: value))
        }
        for (key, value) in customBoolValues {
            options.insert(.custom(key: key, value: value))
        }
        if onStorefrontChange {
            options.insert(.onStorefrontChange { _ in return true })
        }
        // winBackOfferID and introductoryOfferJWS are resolved in PurchaseService
        // because they require the Product object
        return options
    }
}

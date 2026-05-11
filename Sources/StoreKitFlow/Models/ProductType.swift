public enum ProductType: String, Sendable, Codable, CaseIterable {
    case consumable
    case nonConsumable
    case autoRenewable
    case nonRenewing

    public var sectionTitle: String {
        switch self {
        case .consumable:    return "Consumables"
        case .nonConsumable: return "One-Time Purchases"
        case .autoRenewable: return "Subscriptions"
        case .nonRenewing:   return "Passes"
        }
    }
}

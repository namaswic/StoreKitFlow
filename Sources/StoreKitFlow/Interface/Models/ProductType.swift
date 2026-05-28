public enum ProductType: String, Sendable, Codable, CaseIterable {
    case consumable
    case nonConsumable
    case autoRenewable
    case nonRenewing
}

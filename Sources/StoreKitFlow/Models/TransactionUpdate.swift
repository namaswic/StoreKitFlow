public struct TransactionUpdate: Sendable {
    public enum Reason: Sendable {
        case renewal
        case revocation
        case familySharing
        case other
    }

    public let productID: String
    public let transactionID: UInt64
    public let reason: Reason
}

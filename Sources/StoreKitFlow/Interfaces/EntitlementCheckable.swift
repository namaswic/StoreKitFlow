public protocol EntitlementCheckable: Sendable {
    func currentEntitlements(groupID: String?) async -> Set<String>
}

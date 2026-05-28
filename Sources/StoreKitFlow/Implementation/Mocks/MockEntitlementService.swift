public final class MockEntitlementService: EntitlementCheckable, IntroOfferCheckable {
    public let stubbedEntitlements: Set<String>
    public let stubbedIntroEligibility: Bool

    public init(entitlements: Set<String> = [], introEligible: Bool = true) {
        self.stubbedEntitlements = entitlements
        self.stubbedIntroEligibility = introEligible
    }

    public func currentEntitlements() async -> Set<String> {
        stubbedEntitlements
    }

    public func isEligibleForIntroOffer(productID: String) async -> Bool {
        stubbedIntroEligibility
    }
}

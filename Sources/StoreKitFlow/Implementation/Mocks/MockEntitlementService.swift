import Combine

public final class MockEntitlementService: EntitlementCheckable {
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

    public func currentEntitlementsPublisher() -> AnyPublisher<Set<String>, Never> {
        Just(stubbedEntitlements).eraseToAnyPublisher()
    }

    public func isEligibleForIntroOfferPublisher(productID: String) -> AnyPublisher<Bool, Never> {
        Just(stubbedIntroEligibility).eraseToAnyPublisher()
    }
}

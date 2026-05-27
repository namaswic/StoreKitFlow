import Combine

public protocol EntitlementCheckable: Sendable {
    func currentEntitlements() async -> Set<String>
    func isEligibleForIntroOffer(productID: String) async -> Bool
    func currentEntitlementsPublisher() -> AnyPublisher<Set<String>, Never>
    func isEligibleForIntroOfferPublisher(productID: String) -> AnyPublisher<Bool, Never>
}

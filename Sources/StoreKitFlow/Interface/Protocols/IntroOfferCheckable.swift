import Combine

public protocol IntroOfferCheckable: Sendable {
    func isEligibleForIntroOffer(productID: String) async -> Bool
}

public extension IntroOfferCheckable {
    func isEligibleForIntroOfferPublisher(productID: String) -> AnyPublisher<Bool, Never> {
        Future { promise in
            Task { promise(.success(await self.isEligibleForIntroOffer(productID: productID))) }
        }
        .eraseToAnyPublisher()
    }
}

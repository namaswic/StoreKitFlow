import Combine

public protocol EntitlementCheckable: Sendable {
    func currentEntitlements() async -> Set<String>
}

public extension EntitlementCheckable {
    func currentEntitlementsPublisher() -> AnyPublisher<Set<String>, Never> {
        Future { promise in
            Task { promise(.success(await self.currentEntitlements())) }
        }
        .eraseToAnyPublisher()
    }
}

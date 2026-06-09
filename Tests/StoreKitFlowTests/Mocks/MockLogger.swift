@testable import StoreKitFlow

final class MockLogger: StoreKitFlowLogging {
    var isEnabled: Bool = true
    private(set) var loggedEvents: [StoreLogEvent] = []

    func log(_ event: StoreLogEvent) {
        guard isEnabled else { return }
        loggedEvents.append(event)
    }

    func hasEvent(matching predicate: (StoreLogEvent) -> Bool) -> Bool {
        loggedEvents.contains(where: predicate)
    }

    func events(in category: StoreLogCategory) -> [StoreLogEvent] {
        loggedEvents.filter { $0.category == category }
    }
}

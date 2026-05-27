import Foundation

public final class StoreKitFlowLogger: @unchecked Sendable {
    public static let shared = StoreKitFlowLogger()

    public var isEnabled: Bool = true

    private init() {}

    func log(_ event: StoreLogEvent) {
        guard isEnabled else { return }
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[StoreKitFlow][\(time)] \(event.icon) \(event.description)")
    }
}

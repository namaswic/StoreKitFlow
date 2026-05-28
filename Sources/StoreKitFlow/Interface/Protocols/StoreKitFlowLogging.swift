/// Implement this protocol to receive every StoreKit event StoreKitFlow emits.
///
/// Pass your conforming type to `StoreKitFlowStore(configuration:logger:)`.
/// Each `StoreLogEvent` carries a `description`, `category`, `icon`, `isError` flag,
/// and structured `details` — forward whichever fields your logging system needs.
///
/// ```swift
/// final class MyLogger: StoreKitFlowLogging {
///     func log(_ event: StoreLogEvent) {
///         if event.isError {
///             Analytics.trackError(event.description)
///         } else {
///             Analytics.track(event.description)
///         }
///     }
/// }
///
/// let store = StoreKitFlowStore(configuration: config, logger: MyLogger())
/// ```
public protocol StoreKitFlowLogging: AnyObject {
    var isEnabled: Bool { get set }
    func log(_ event: StoreLogEvent)
}

public extension StoreKitFlowLogging {
    var isEnabled: Bool {
        get { true }
        set {}
    }
}

public protocol StoreKitFlowLogging: AnyObject {
    var isEnabled: Bool { get set }
    func log(_ event: StoreLogEvent)
}

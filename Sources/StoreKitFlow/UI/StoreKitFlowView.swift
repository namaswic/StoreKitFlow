import SwiftUI

public struct StoreKitFlowView: View {
    @StateObject private var store: StoreKitFlowStore

    public init(configuration: StoreKitFlowConfiguration) {
        _store = StateObject(wrappedValue: StoreKitFlowStore(configuration: configuration))
    }

    public var body: some View {
        EmptyView()
            .environmentObject(store)
            .task { await store.initialize() }
    }
}

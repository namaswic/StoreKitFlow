import SwiftUI
import StoreKitFlow

@main
struct StoreKitFlowDemoApp: App {
    private static let configuration = StoreKitFlowConfiguration(
        productIDs: [
            "com.storekitflow.demo.coins10",
            "com.storekitflow.demo.removeads",
            "com.storekitflow.demo.themes",
            "com.storekitflow.demo.pro.monthly",
            "com.storekitflow.demo.pro.yearly",
            "com.storekitflow.demo.pro.monthly.upfront",
            "com.storekitflow.demo.basic.monthly",
            "com.storekitflow.demo.basic.yearly",
            "com.storekitflow.demo.pass.30days"
        ],
        subscriptionGroupIDs: ["763D6759"],
        appStoreID: "1632168877",
        enableTransactionCache: true
    )

    @StateObject private var store = StoreKitFlowStore(configuration: Self.configuration)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task { await store.initialize() }
        }
    }
}

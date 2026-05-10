import SwiftUI
import StoreKitFlow

@main
struct StoreKitFlowDemoApp: App {
    @StateObject private var store = StoreKitFlowStore(
        productService: ProductService(),
        entitlementService: EntitlementService(),
        transactionService: TransactionService()
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    store.productIDs = [
                        // Consumables
                        "com.storekitflow.demo.coins10",
                        // Non-Consumables
                        "com.storekitflow.demo.removeads",
                        "com.storekitflow.demo.themes",
                        // Auto-Renewable — Pro group
                        "com.storekitflow.demo.pro.monthly",
                        "com.storekitflow.demo.pro.yearly",
                        "com.storekitflow.demo.pro.monthly.upfront",
                        // Auto-Renewable — Basic group
                        "com.storekitflow.demo.basic.monthly",
                        "com.storekitflow.demo.basic.yearly",
                        // Non-Renewing
                        "com.storekitflow.demo.pass.30days"
                    ]
                    await store.initialize()
                }
        }
    }
}

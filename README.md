# StoreKitFlow

SwiftUI-first StoreKit 2 framework that simplifies in-app purchases with a protocol-based service layer, reactive store, and structured transaction logging — configured in one `StoreKitFlowConfiguration` call. Includes a full interactive API explorer you can embed directly in your app.

## Screenshots

<p align="center">
  <img src="Screenshots/products.png" width="200">
  <img src="Screenshots/logs.png" width="200">
  <img src="Screenshots/sk_views.png" width="200">
</p>
<p align="center">
  <img src="Screenshots/by_view_product.png" width="200">
  <img src="Screenshots/by_view_store.png" width="200">
  <img src="Screenshots/by_view_subscription.png" width="200">
</p>

## Getting Started

See [GETTING_STARTED.md](GETTING_STARTED.md) for installation, configuration, and StoreKit setup instructions.

## Quick Setup

```swift
import SwiftUI
import StoreKitFlow

@main
struct MyApp: App {
    private static let configuration = StoreKitFlowConfiguration(
        productIDs: ["com.myapp.coins", "com.myapp.pro.monthly"],
        subscriptionGroupIDs: ["YOUR_GROUP_ID"],
        appStoreID: "YOUR_APP_STORE_ID"
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
```

## StoreKitFlowExplorerView

Embed the full interactive StoreKit explorer in your own app for debugging and previewing:

```swift
// As your root view during development
StoreKitFlowView(configuration: config) {
    StoreKitFlowExplorerView()
}

// Or as a debug sheet
.sheet(isPresented: $showDebugger) {
    StoreKitFlowExplorerView()
        .environmentObject(store)
}
```

The explorer gives you:
- **Products** — browse loaded products by type with purchase support
- **Logs** — live transaction and entitlement event log with filtering
- **SK Views** — interactive reference for all StoreKit views and modifiers
- **By View** — per-view deep-dive for `ProductView`, `StoreView`, `SubscriptionStoreView`, and `SubscriptionOfferView`
- **Guide** — reference for product types, offer types, and payment modes

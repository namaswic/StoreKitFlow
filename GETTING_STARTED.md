# Getting Started with StoreKitFlow

## Installation

### Swift Package Manager

Add StoreKitFlow to your project in Xcode:

1. Go to **File → Add Package Dependencies…**
2. Enter the repository URL:
   ```
   https://github.com/namaswic/StoreKitFlow
   ```
3. Select **"Up to Next Major Version"** and click **Add Package**
4. Add `StoreKitFlow` to your app target

Or add it directly to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/namaswic/StoreKitFlow", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["StoreKitFlow"]
    )
]
```

Then import it wherever needed:

```swift
import StoreKitFlow
```

---

## Requirements

- iOS 17+ / macOS 14+
- Swift 5.9+
- Xcode 15+

---

## Overview

StoreKitFlow is a SwiftUI-first StoreKit 2 framework. Setup has two parts:

1. **StoreKit configuration file** — a local `.storekit` file for testing in the simulator
2. **StoreKitFlowConfiguration** — tells the library which product IDs to load at runtime

These two must use matching product IDs. The `.storekit` file is only needed for local testing; in production StoreKit fetches products directly from App Store Connect.

---

## Step 1 — Create a StoreKit Configuration File

This file acts as a local product catalog for the iOS Simulator. You only need it during development.

1. In Xcode, go to **File → New → File from Template…**
2. Search for **"StoreKit Configuration File"** and click Next
3. Name it (e.g. `Products.storekit`) and save it inside your app target folder
4. Add your products in the Xcode StoreKit editor — make sure the **Product ID** values match exactly what you register in App Store Connect

> **Tip:** You do not need to add the `.storekit` file to any app target. It should not be bundled in your app.

---

## Step 2 — Point Your Scheme at the Configuration File

1. In Xcode, click the scheme name next to the device picker at the top
2. Select **"Edit Scheme…"**
3. Go to **Run → Options**
4. Under **StoreKit Configuration**, select your `.storekit` file
5. Click **Close**

Now when you run the app in the simulator, StoreKit will use your local product catalog instead of hitting App Store Connect.

---

## Step 3 — Configure StoreKitFlow

In your `App` entry point, create a `StoreKitFlowConfiguration` with the same product IDs you defined in your `.storekit` file:

```swift
import SwiftUI
import StoreKitFlow

@main
struct MyApp: App {
    private static let configuration = StoreKitFlowConfiguration(
        productIDs: [
            "com.myapp.coins",
            "com.myapp.premium",
            "com.myapp.pro.monthly",
            "com.myapp.pro.yearly"
        ],
        subscriptionGroupIDs: ["YOUR_GROUP_ID"],  // from your .storekit file
        appStoreID: "YOUR_APP_STORE_ID"           // optional, used for App Store Overlay
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

---

## Important: Product IDs Must Match

The product IDs in `StoreKitFlowConfiguration` must exactly match the `productID` values in your `.storekit` file during local testing.

| Environment | Where products come from |
|---|---|
| Simulator (development) | Your `.storekit` configuration file |
| Device / TestFlight / App Store | App Store Connect |

If you see `Fetched 0 product(s)` in the logs, it means the product IDs in code don't match what's in the active StoreKit configuration file. Check:
- The scheme is pointing at the right `.storekit` file (Edit Scheme → Run → Options)
- The `productID` values in your `.storekit` file exactly match the strings in `StoreKitFlowConfiguration`

---

## Subscription Group IDs

Each subscription group in your `.storekit` file has an `id` field. Pass these to `subscriptionGroupIDs` in your configuration. You can find the group ID:

- In your `.storekit` file: the `"id"` field on each subscription group object
- In App Store Connect: under your subscription group settings

---

## Using Multiple StoreKit Configuration Files

You can create multiple `.storekit` files (e.g. `Demo.storekit`, `Test.storekit`) with different product catalogs and switch between them via the scheme:

**Edit Scheme → Run → Options → StoreKit Configuration**

Update `StoreKitFlowConfiguration` to use the matching product IDs for whichever file is active. The `storeKitConfigFileName` parameter is a documentation hint — it does not switch files automatically.

---

## Logs

StoreKitFlow logs all store activity to the console with a `[StoreKitFlow]` prefix. Key log lines:

```
[StoreKitFlow] Fetching 4 product(s)         ← products requested
[StoreKitFlow] Fetched 4 product(s)          ← products loaded successfully
[StoreKitFlow] Fetched 0 product(s)          ← ID mismatch or wrong .storekit file
[StoreKitFlow] No active entitlements        ← user has no purchases yet
```

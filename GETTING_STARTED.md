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
    .target(name: "YourTarget", dependencies: ["StoreKitFlow"])
]
```

**Requirements:** iOS 17+ / macOS 14+ · Swift 5.9+ · Xcode 15+

---

## Why StoreKitFlow

StoreKit 2 is powerful but has several production pitfalls that are easy to miss and hard to debug. StoreKitFlow solves them out of the box.

### 1. StoreKit has no local transaction history

StoreKit delivers transactions and then forgets them. If your app is killed mid-renewal, or `Transaction.updates` is cancelled, that renewal is silently lost — you have no record it ever happened.

StoreKitFlow persists every verified transaction to disk. Each entry carries:
- Full transaction metadata (product ID, dates, environment, app account token)
- **How many times StoreKit surfaced it** — so you can spot duplicate deliveries
- **Which code path delivered it each time** — purchase, updates stream, unfinished queue, or reconciliation

```swift
let entry = store.transactionHistory.first!
print(entry.deliveryCount)   // 3 — StoreKit delivered this renewal 3 times
print(entry.deliveryLog)     // [storePurchase @ 10:01, transactionUpdates @ 10:01, reconciliation @ 10:04]
```

### 2. Missed renewals are automatically recovered

When a subscription renews while the app is in the background and gets killed, the renewal transaction is never processed. On next launch, StoreKitFlow runs a reconciliation pass — cross-checking `Transaction.currentEntitlements` against the cache — and finishes any missed renewals automatically.

You don't write any code for this. It runs inside `initialize()`.

### 3. Re-subscribing after expiry silently succeeds without a payment sheet

This is a [known StoreKit production bug](https://stackoverflow.com/q/77355821): if there are unfinished renewal transactions in the queue, StoreKit resolves a new purchase against them instead of initiating a fresh payment. The user never sees a confirmation sheet, and your purchase call returns `.success` without any charge.

StoreKitFlow exposes one parameter to fix it:

```swift
await store.purchase(product, shouldProcessUnfinishedTransactions: true)
```

Pass this whenever a user is re-subscribing after expiry. It drains the unfinished queue first so StoreKit always presents a real payment sheet.

### 4. Typed purchase outcomes — the compiler enforces every case

Raw StoreKit mixes success cases, errors, and edge cases across different APIs. StoreKitFlow gives you a single exhaustive enum:

```swift
switch await store.purchase(product) {
case .success(let productID, let transactionID, _, let appAccountToken):
    grantAccess(productID)
case .pending:
    // Ask to Buy / billing issue — DO NOT grant access
    // The final result arrives via onTransactionUpdate when resolved
    showPendingUI()
case .cancelled:
    break
case .unverified:
    // StoreKit's cryptographic check failed — treat as not purchased
    break
case .failed(let error):
    switch error {
    case .productNotFound:    showError("Product unavailable")
    case .purchaseFailed(let e): showError(e.localizedDescription)
    case .unknown(let e):     reportToAnalytics(e)
    }
}
```

### 5. Every `Product.PurchaseOption` in one struct

`PurchaseAttributes` covers every option StoreKit exposes — with sane defaults so you only set what you need:

```swift
// Link the purchase to a backend user
PurchaseAttributes(appAccountToken: currentUser.uuid)

// Buy multiple consumables at once
PurchaseAttributes(quantity: 5)

// Pass server-readable metadata for attribution or A/B testing
PurchaseAttributes(
    customStringValues: ["campaign": "summer24"],
    customDoubleValues: ["discount": 0.15],
    customBoolValues: ["isPromotion": true]
)

// Apply a win-back offer (iOS 18+) — resolved to Product.SubscriptionOffer automatically
PurchaseAttributes(winBackOfferID: "win_back_6month")

// Verify introductory offer eligibility with a server-signed JWS token
PurchaseAttributes(introductoryOfferJWS: jwsFromServer)

// Simulate Ask to Buy in sandbox
PurchaseAttributes(simulatesAskToBuy: true)
```

### 6. An interactive StoreKit explorer you can ship in your app

The `StoreKitFlowExplorerView` is not just a demo — it's a SwiftUI view you embed in your own debug builds. It gives your team:

- **Live previews** of every StoreKit view (`ProductView`, `StoreView`, `SubscriptionStoreView`, `SubscriptionOfferView`) with real purchases
- **Variant switcher** — flip between all control styles, container placements, and option group layouts without dismissing the sheet
- **Dark mode toggle + Dynamic Type picker** — test accessibility without leaving the preview
- **Copyable modifier code** — tap any modifier line to copy it directly to the clipboard
- **Structured logs** — every store event with category, timestamp, and full detail
- **Transaction cache** — browse the full on-device history with delivery trails

```swift
// Add to your debug settings or shake gesture handler
.sheet(isPresented: $showDebugger) {
    StoreKitFlowExplorerView()
        .environmentObject(store)
}
```

### 7. Protocol-based — fully injectable for testing

Every component is swappable. You can test purchase flows, cache behaviour, and entitlement logic without hitting StoreKit or the file system:

```swift
let store = StoreKitFlowStore(
    productService: MockProductService(products: myTestProducts),
    entitlementService: MockEntitlementService(entitlements: ["com.myapp.pro"]),
    transactionService: MockTransactionService(),
    cache: InMemoryCache(),
    configuration: StoreKitFlowConfiguration(productIDs: [...])
)
```

---

## Quick Setup

### Step 1 — Create a StoreKit Configuration File

This file is your local product catalog for the simulator. You only need it during development.

1. In Xcode: **File → New → File from Template… → StoreKit Configuration File**
2. Name it (e.g. `Products.storekit`) and save it in your project folder
3. Add your products — make sure the **Product ID** values match exactly what you register in App Store Connect

> The `.storekit` file should **not** be added to your app target or bundled in your app.

### Step 2 — Point your scheme at the file

1. Click the scheme name → **Edit Scheme…**
2. Go to **Run → Options**
3. Under **StoreKit Configuration**, select your `.storekit` file

### Step 3 — Configure and initialize

```swift
import SwiftUI
import StoreKitFlow

@main
struct MyApp: App {
    private static let configuration = StoreKitFlowConfiguration(
        productIDs: [
            "com.myapp.coins",
            "com.myapp.pro.monthly",
            "com.myapp.pro.yearly"
        ],
        subscriptionGroupIDs: ["YOUR_GROUP_ID"],
        appStoreID: "YOUR_APP_STORE_ID",
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
```

`initialize()` does the following in order:
1. Fetches products from App Store Connect (or your `.storekit` file in the simulator)
2. Loads current entitlements
3. Drains any unfinished transactions from previous sessions
4. Runs the reconciliation pass to recover missed renewals
5. Starts listening for external transaction updates (renewals, revocations, family sharing)

---

## Purchasing

```swift
struct BuyButton: View {
    let product: StoreProduct
    @EnvironmentObject private var store: StoreKitFlowStore

    var body: some View {
        Button(product.displayPrice) {
            Task {
                switch await store.purchase(product) {
                case .success:       grantAccess()
                case .pending:       showPendingMessage()
                case .cancelled:     break
                case .unverified:    break
                case .failed(let e): showError(e)
                }
            }
        }
        .disabled(store.isPurchasing)
    }
}
```

### Checking entitlement

```swift
// Reactive — updates automatically after any purchase or restore
store.isPurchased(product)

// Or observe the published set directly
store.purchasedProductIDs.contains("com.myapp.pro.monthly")
```

### Restoring purchases

Required by App Store Review guidelines for apps with non-consumables or auto-renewable subscriptions. Only call in response to an explicit user action.

```swift
Button("Restore Purchases") {
    Task { await store.restorePurchases() }
}
```

---

## Handling External Transactions

Renewals, revocations, and family sharing events arrive outside your direct purchase flow. Register a handler **before** calling `initialize()`:

```swift
store.onTransactionUpdate = { update in
    switch update.reason {
    case .renewal:
        // Re-check subscription status via Product.SubscriptionInfo.Status
        // Do NOT grant access based on this callback alone — StoreKit can
        // re-deliver the same transaction 2–3 times before finish() completes
        await refreshSubscriptionStatus()
    case .revocation:
        await revokeAccess(for: update.productID)
    case .familySharing:
        await grantFamilyAccess(for: update.productID)
    case .other:
        break
    }
}

await store.initialize()
```

---

## Native StoreKit Views

If you use `ProductView`, `SubscriptionStoreView`, or other native StoreKit views, purchases complete outside `store.purchase()`. Call `reconcile()` after completion to record the transaction in the cache:

```swift
ProductView(id: "com.myapp.pro.monthly")
    .onInAppPurchaseCompletion { _, result in
        if case .success = result {
            await store.reconcile()
        }
    }
```

---

## Transaction Cache

The cache gives you a persistent, queryable audit trail. Enable it in configuration:

```swift
StoreKitFlowConfiguration(productIDs: [...], enableTransactionCache: true)
```

```swift
// Browse history — oldest first
store.transactionHistory

// Inspect a transaction
let entry: CachedTransaction = store.transactionHistory.last!
entry.productID          // "com.myapp.pro.monthly"
entry.source             // .purchase / .renewal / .unfinished / .restore
entry.environment        // "Sandbox" or "Production"
entry.finishedAt         // when finish() was called
entry.deliveryCount      // how many times StoreKit surfaced this transaction
entry.deliveryLog        // full trail with path + timestamp per delivery
```

**Delivery paths:**

| Path | Meaning |
|---|---|
| `store.purchase()` | Direct purchase via your UI |
| `Transaction.updates` | Renewal, revocation, family sharing, or Ask to Buy approval |
| `Transaction.unfinished` | Recovered from unfinished queue on launch |
| `reconciliation` | Missed renewal caught by the reconciliation pass |

```swift
// Clear the local cache (does not affect App Store purchases)
store.clearTransactionHistory()
```

---

## Dependency Injection & Testing

### Mock services

```swift
let store = StoreKitFlowStore(
    productService: MockProductService(products: [
        StoreProduct(
            id: "com.test.pro",
            displayName: "Pro",
            description: "Full access",
            displayPrice: "$4.99",
            price: 4.99,
            type: .autoRenewable
        )
    ]),
    entitlementService: MockEntitlementService(
        entitlements: [],
        introEligible: true
    ),
    transactionService: MockTransactionService(),
    configuration: StoreKitFlowConfiguration(productIDs: ["com.test.pro"])
)
```

### Custom in-memory cache

```swift
@MainActor
final class InMemoryCache: TransactionCaching {
    private var entries: [CachedTransaction] = []
    func all() -> [CachedTransaction] { entries }
    func record(_ entry: CachedTransaction) {
        // Append delivery events to existing entry, or add new
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = CachedTransaction(
                id: entries[i].id, originalID: entries[i].originalID,
                productID: entries[i].productID, productType: entries[i].productType,
                purchaseDate: entries[i].purchaseDate, expirationDate: entries[i].expirationDate,
                revocationDate: entries[i].revocationDate, appAccountToken: entries[i].appAccountToken,
                environment: entries[i].environment,
                finishedAt: entries[i].finishedAt ?? entry.finishedAt,
                source: entries[i].source,
                deliveryLog: entries[i].deliveryLog + entry.deliveryLog
            )
        } else {
            entries.append(entry)
        }
    }
    func reconcile() async -> [Transaction] { [] }
    func clearAll() { entries = [] }
}
```

### Silent logger

```swift
final class SilentLogger: StoreKitFlowLogging {
    var isEnabled = false
    func log(_ event: StoreLogEvent) {}
}

let store = StoreKitFlowStore(..., logger: SilentLogger())
```

---

## Combine Support

Every async method has a publisher variant via default protocol extensions:

```swift
productService.fetchProductsPublisher(ids: ids)
    .sink { completion in ... } receiveValue: { products in ... }
    .store(in: &cancellables)

entitlementService.currentEntitlementsPublisher()
    .sink { productIDs in ... }
    .store(in: &cancellables)
```

---

## Troubleshooting

**`Fetched 0 product(s)`**
The product IDs in `StoreKitFlowConfiguration` don't match the `.storekit` file. Check:
- Edit Scheme → Run → Options → StoreKit Configuration points at the right file
- The `productID` strings in your `.storekit` file exactly match the strings in your configuration

**Purchase returns `.success` without showing a payment sheet**
Unfinished transactions from a previous session are blocking the new purchase. Pass `shouldProcessUnfinishedTransactions: true`:
```swift
await store.purchase(product, shouldProcessUnfinishedTransactions: true)
```

**Renewals not appearing in the cache**
Make sure `enableTransactionCache: true` is set in your configuration. Without it, `transactionHistory` stays empty.

**`onTransactionUpdate` fires multiple times for the same renewal**
This is expected StoreKit behaviour — the same transaction can be re-delivered 2–3 times before `finish()` completes. StoreKitFlow deduplicates within the listener session. For subscription entitlement, always derive access from `Product.SubscriptionInfo.Status`, not the callback count.

---

## Protocol Reference

| Protocol | Core requirement | Default extensions |
|---|---|---|
| `ProductFetchable` | `fetchProducts(ids:) async throws` | `fetchProductsPublisher(ids:)` |
| `Purchasable` | `purchase(product:attributes:) async throws` | `purchasePublisher(product:attributes:)` |
| `EntitlementCheckable` | `currentEntitlements() async` | `currentEntitlementsPublisher()` |
| `IntroOfferCheckable` | `isEligibleForIntroOffer(productID:) async` | `isEligibleForIntroOfferPublisher(productID:)` |
| `TransactionObservable` | `updates() -> AsyncStream` | `updatesPublisher()` |
| `TransactionCaching` | `all()`, `record()`, `reconcile()`, `clearAll()` | — |
| `StoreKitFlowLogging` | `log(_ event:)` | — |
| `StoreObservable` | Full store surface | — |

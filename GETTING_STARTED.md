# Getting Started with StoreKitFlow

## Table of Contents

1. [Installation](#installation)
2. [Why StoreKitFlow](#why-storekitflow)
3. [Quick Setup](#quick-setup)
4. [Purchasing](#purchasing)
5. [Subscription Offers](#subscription-offers)
6. [Handling External Transactions](#handling-external-transactions)
7. [Native StoreKit Views](#native-storekitviews)
8. [Transaction Cache](#transaction-cache)
9. [Working with Products](#working-with-products)
10. [Dependency Injection & Testing](#dependency-injection--testing)
11. [Custom Logging](#custom-logging)
12. [Combine Support](#combine-support)
13. [Troubleshooting](#troubleshooting)
14. [Protocol & Model Reference](#protocol--model-reference)

---

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
    case .productNotFound:        showError("Product unavailable")
    case .purchaseFailed(let e):  showError(e.localizedDescription)
    case .unknown(let e):         reportToAnalytics(e)
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

// Apply a win-back offer (iOS 18+)
PurchaseAttributes(winBackOfferID: "win_back_6month")

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
    productService: MockProductService(products: MockData.products),
    entitlementService: MockEntitlementService(entitlements: ["com.myapp.pro"]),
    transactionService: MockTransactionService(),
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

> The `.storekit` file should **not** be added to your app target or bundled in your app. Select it via Edit Scheme → Run → Options → StoreKit Configuration.

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

### Basic purchase

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

`isPurchased(_:)` and `purchasedProductIDs` reflect what was loaded during `initialize()` and updated after each purchase or restore. They do not re-query Apple on every call — they are a reactive snapshot of the last known entitlement state. For auto-renewable subscriptions, always derive the authoritative access decision from `Product.SubscriptionInfo.Status`, not from this snapshot alone.

```swift
// Reactive — updates automatically after any purchase or restore
store.isPurchased(product)

// Observe the full set directly
store.purchasedProductIDs.contains("com.myapp.pro.monthly")
```

### Restoring purchases

Required by App Store Review guidelines for apps with non-consumables or auto-renewable subscriptions. Only call in response to an explicit user action — `AppStore.sync()` may present an Apple ID sign-in sheet.

```swift
Button("Restore Purchases") {
    Task { await store.restorePurchases() }
}
```

### Re-subscribing after expiry

When a subscription lapses and a user tries to re-subscribe, StoreKit may silently return `.success` without showing a payment sheet if unfinished renewal transactions are still in the queue. Pass `shouldProcessUnfinishedTransactions: true` to drain the queue first:

```swift
// Use this on your re-subscribe button, not on first-time purchase
await store.purchase(product, shouldProcessUnfinishedTransactions: true)
```

---

## Subscription Offers

StoreKit has three distinct offer types with different eligibility requirements, server-side flows, and `PurchaseAttributes` usage. They are not interchangeable.

### Introductory offers

**Who:** New subscribers who have never had an active or expired subscription in this group.

**How:** Apple determines eligibility automatically. You can optionally verify server-side using a JWS token, or check eligibility via `StoreProduct.introductoryOffer` and `isEligibleForIntroOffer`:

```swift
// Check eligibility (queries Apple's servers)
let eligible = await entitlementService.isEligibleForIntroOffer(productID: product.id)

// Inspect the offer details from the product
if let offer = product.introductoryOffer {
    print(offer.displayPrice)    // "$0.00" for free trial
    print(offer.period)          // "3 months"
    print(offer.paymentMode)     // .free / .payAsYouGo / .payUpFront
}

// If you have a server-signed JWS for eligibility verification:
await store.purchase(product, attributes: PurchaseAttributes(
    introductoryOfferJWS: jwsFromServer
))
```

### Promotional offers

**Who:** Current or previously subscribed users — Apple does not automatically apply these. Your backend controls eligibility.

**How:** Configure the offer in App Store Connect, sign it server-side, and pass the offer ID. The server signature is verified by Apple:

```swift
// Inspect available promotional offers on the product
for offer in product.promotionalOffers {
    print(offer.id)           // "promo_winback_3month"
    print(offer.displayName)  // "3 Months for $1.99"
    print(offer.paymentMode)  // .payAsYouGo / .payUpFront / .free
    print(offer.displayPrice) // "$1.99"
    print(offer.period)       // "3 months"
}

// Apply the offer — your server generates the signature
await store.purchase(product, attributes: PurchaseAttributes(
    promotionalOfferID: "promo_winback_3month"
))
```

> Note: `promotionalOfferID` alone does not pass the server signature — StoreKit requires a signed payload for promotional offers. If your app needs full signature support, pass the signature components via `customStringValues` and handle them in a `Purchasable` implementation that calls the appropriate StoreKit API directly.

### Win-back offers (iOS 18+ / macOS 15+)

**Who:** Lapsed subscribers — users whose subscription expired. Apple manages eligibility.

**How:** Configure in App Store Connect, then pass the offer ID. StoreKitFlow resolves it to the `Product.SubscriptionOffer` automatically:

```swift
// Inspect available win-back offers on the product
for offer in product.winBackOffers {
    print(offer.id)           // "win_back_6month"
    print(offer.displayPrice) // "$2.99"
    print(offer.period)       // "6 months"
    print(offer.paymentMode)  // .payAsYouGo / .payUpFront / .free
}

// Apply the offer
await store.purchase(product, attributes: PurchaseAttributes(
    winBackOfferID: "win_back_6month"
))
```

Win-back offers are only available on iOS 18+ / macOS 15+. StoreKitFlow guards the API with `#available` — passing a `winBackOfferID` on earlier OS versions is silently ignored.

### Offer type comparison

| | Introductory | Promotional | Win-back |
|---|---|---|---|
| Who qualifies | New subscribers | Current or lapsed — your logic | Lapsed — Apple's logic |
| Server signature required | No (optional JWS) | Yes | No |
| OS requirement | iOS 17+ | iOS 17+ | iOS 18+ |
| `PurchaseAttributes` field | `introductoryOfferJWS` | `promotionalOfferID` | `winBackOfferID` |
| Works in sandbox | Yes | Yes | Inconsistently |

---

## Handling External Transactions

Renewals, revocations, and family sharing events arrive outside your direct purchase flow via `Transaction.updates`. Register a handler **before** calling `initialize()`:

```swift
store.onTransactionUpdate = { update in
    switch update.reason {
    case .renewal:
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

### Critical: do not grant access directly from this callback

`onTransactionUpdate` can fire 2–3 times for the same renewal transaction before `finish()` completes. This is documented StoreKit behaviour — the same transaction ID is re-delivered until `finish()` is acknowledged by Apple's servers.

StoreKitFlow deduplicates deliveries within a session and merges them in the cache delivery log, but the **callback still fires once per delivery**. Do not use it to directly flip an access flag:

```swift
// WRONG — fires multiple times for one renewal
store.onTransactionUpdate = { update in
    if case .renewal = update.reason {
        grantAccess(for: update.productID)  // called 2–3x for one renewal
    }
}

// CORRECT — re-read the authoritative subscription status
store.onTransactionUpdate = { update in
    if case .renewal = update.reason {
        let statuses = try? await Product.SubscriptionInfo.status(for: groupID)
        let isActive = statuses?.contains { $0.state == .subscribed } ?? false
        updateAccess(isActive)
    }
}
```

The delivery trail in `store.transactionHistory` shows exactly how many times each transaction was delivered and via which path — useful when debugging duplicate-delivery reports.

---

## Native StoreKit Views

If you use `ProductView`, `SubscriptionStoreView`, or other native StoreKit views, purchases complete outside `store.purchase()`. Call `reconcile()` after completion to record the transaction in the cache and update `purchasedProductIDs`:

```swift
ProductView(id: "com.myapp.pro.monthly")
    .onInAppPurchaseCompletion { _, result in
        if case .success = result {
            await store.reconcile()
        }
    }
```

`reconcile()` cross-references `Transaction.currentEntitlements` against the cache and finishes any transactions that were completed but not yet recorded. You can also call it any time you suspect the cache is out of sync — it is safe to call repeatedly.

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
entry.environment        // "Xcode", "Sandbox", or "Production"
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

**Environment values:**

| Value | When |
|---|---|
| `"Xcode"` | Simulator with a `.storekit` configuration file |
| `"Sandbox"` | Real device with a sandbox Apple ID, or TestFlight |
| `"Production"` | App Store distribution |

```swift
// Clear the local cache (does not affect App Store purchases)
store.clearTransactionHistory()
```

The cache file lives at `Application Support/StoreKitFlow/transactions.json`. It is append-only — records are never deleted, only updated with new delivery events.

---

## Working with Products

### StoreProduct

`StoreProduct` is StoreKitFlow's type-safe wrapper around `Product`. It is fully `Sendable` and `Hashable` and safe to use across concurrency boundaries:

```swift
let product: StoreProduct = store.products.first!

product.id              // "com.myapp.pro.monthly"
product.displayName     // "Pro Monthly"
product.description     // "Full access to all features"
product.displayPrice    // "$4.99"
product.price           // Decimal(4.99)
product.type            // .autoRenewable
product.familyShareable // true/false — whether Family Sharing is enabled
```

### Offer details on StoreProduct

```swift
// Introductory offer (nil if none configured or user not eligible)
if let intro = product.introductoryOffer {
    intro.paymentMode   // .free / .payAsYouGo / .payUpFront
    intro.displayPrice  // "$0.00" for free trial
    intro.period        // "7 days"
}

// Promotional offers (empty if none configured in App Store Connect)
for offer in product.promotionalOffers {
    offer.id            // "promo_3month"
    offer.displayName   // "3 Months for $1.99"
    offer.paymentMode   // .payAsYouGo
    offer.displayPrice  // "$1.99"
    offer.period        // "3 months"
}

// Win-back offers (iOS 18+, empty on earlier OS)
for offer in product.winBackOffers {
    offer.id            // "win_back_6month"
    offer.paymentMode   // .free
    offer.displayPrice  // "$0.00"
    offer.period        // "6 months"
}
```

### PaymentMode

`PaymentMode` describes how an offer charges the user:

| Case | Meaning |
|---|---|
| `.free` | Free trial — no charge during the offer period |
| `.payAsYouGo` | Discounted recurring charge — billed each period at the offer price |
| `.payUpFront` | Single upfront charge for the full offer period |

### ProductType

| Case | Description |
|---|---|
| `.consumable` | Used once, can be purchased multiple times (coins, credits, lives) |
| `.nonConsumable` | Purchased once, owned forever (unlock, theme, remove ads) |
| `.autoRenewable` | Recurring subscription — renews automatically until cancelled |
| `.nonRenewing` | Time-limited access — does not auto-renew; you manage expiry |

### EntitlementStatus

`EntitlementStatus` describes the state of a subscription or purchase:

```swift
switch entitlementStatus {
case .active:   // Currently entitled — grant access
case .expired:  // Subscription lapsed — revoke access
case .revoked:  // Apple issued a refund or revoked (family sharing) — revoke access
}
```

---

## Dependency Injection & Testing

### Using MockData for instant test products

`MockData.products` provides 9 ready-made `StoreProduct` instances covering all four product types — consumables, non-consumables, auto-renewable subscriptions (two groups, three price points), and a non-renewing pass. Use it in unit tests and previews without writing any fixture data:

```swift
let store = StoreKitFlowStore(
    productService: MockProductService(products: MockData.products),
    entitlementService: MockEntitlementService(entitlements: []),
    transactionService: MockTransactionService(),
    configuration: StoreKitFlowConfiguration(productIDs: MockData.products.map(\.id))
)
```

Or filter to just the types you need:

```swift
let subscriptions = MockData.products.filter { $0.type == .autoRenewable }
```

### SwiftUI previews with a mock store

`StoreObservable` is the protocol that `StoreKitFlowStore` conforms to. Views that accept `StoreKitFlowStore` as an `@EnvironmentObject` can be previewed with a fully mocked store — no StoreKit, no network:

```swift
#Preview {
    ProductsView()
        .environmentObject(
            StoreKitFlowStore(
                productService: MockProductService(products: MockData.products),
                entitlementService: MockEntitlementService(
                    entitlements: ["com.storekitflow.demo.pro.monthly"],
                    introEligible: false
                ),
                transactionService: MockTransactionService(),
                configuration: StoreKitFlowConfiguration(
                    productIDs: MockData.products.map(\.id)
                )
            )
        )
}
```

### Simulating purchase failures

`MockPurchaseService` accepts a `shouldFail` flag for testing error paths:

```swift
let store = StoreKitFlowStore(
    productService: MockProductService(),
    purchaseService: MockPurchaseService(shouldFail: true),
    entitlementService: MockEntitlementService(),
    transactionService: MockTransactionService(),
    configuration: StoreKitFlowConfiguration(productIDs: [...])
)
// store.purchase(product) will return .failed(.purchaseFailed(...))
```

### Custom in-memory cache

For unit tests where you want to assert on cache state without touching disk:

```swift
@MainActor
final class InMemoryCache: TransactionCaching {
    private var entries: [CachedTransaction] = []
    func all() -> [CachedTransaction] { entries }
    func record(_ entry: CachedTransaction) {
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

---

## Custom Logging

Pass your own logger to receive every `StoreLogEvent` StoreKitFlow emits. Forward it to OSLog, Datadog, Crashlytics, or any analytics system:

```swift
final class MyLogger: StoreKitFlowLogging {
    func log(_ event: StoreLogEvent) {
        // event.description   — human-readable summary
        // event.category      — .productService / .purchaseFlow / .transactions / etc.
        // event.isError       — true for failures and unverified transactions
        // event.details       — structured key-value pairs with full context
        // event.icon          — SF Symbol name for the event type
        if event.isError {
            Analytics.trackError(event.description)
        } else {
            Analytics.track(event.description)
        }
    }
}

let store = StoreKitFlowStore(configuration: config, logger: MyLogger())
```

`isEnabled` has a default no-op implementation — you only need to implement `log(_:)`. The built-in `StoreKitFlowLogger.shared` is used when no logger is supplied; it prints to the console with timestamp and SF Symbol icon.

To silence all logging in tests:

```swift
final class SilentLogger: StoreKitFlowLogging {
    func log(_ event: StoreLogEvent) {}
}

let store = StoreKitFlowStore(..., logger: SilentLogger())
```

### Log categories

| Category | Events |
|---|---|
| `productService` | Fetch started, completed, failed |
| `purchaseFlow` | Purchase started, succeeded, cancelled, pending, failed |
| `transactions` | Received, verified, unverified, finished, unfinished found |
| `entitlements` | Current entitlements loaded |
| `restore` | Restore started, completed, failed |
| `cache` | Transaction cached, reconciliation found/complete |

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

entitlementService.isEligibleForIntroOfferPublisher(productID: id)
    .sink { eligible in ... }
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
Expected StoreKit behaviour — the same transaction is re-delivered 2–3 times before `finish()` completes. Never grant access inside this callback directly. Re-read `Product.SubscriptionInfo.Status` to get the authoritative subscription state. See [Handling External Transactions](#handling-external-transactions).

**Win-back offer not appearing in sandbox**
Win-back offer presentation in sandbox is inconsistent as of iOS 18.0 — this is an Apple limitation. Test win-back flows in a production build or TestFlight.

**`isEligibleForIntroOffer` returns `false` unexpectedly in sandbox**
The sandbox account has a subscription history for this product. Reset it in Settings → App Store → Sandbox Account → Manage, or use a fresh sandbox account.

**Introductory offer shown to ineligible users**
`product.introductoryOffer` being non-nil only means the offer exists — it does not mean the current user qualifies. Always check `isEligibleForIntroOffer(productID:)` before surfacing introductory offer UI.

---

## Protocol & Model Reference

### Protocols

| Protocol | Core requirement | Default extensions |
|---|---|---|
| `ProductFetchable` | `fetchProducts(ids:) async throws` | `fetchProductsPublisher(ids:)` |
| `Purchasable` | `purchase(product:attributes:) async throws` | `purchasePublisher(product:attributes:)` |
| `EntitlementCheckable` | `currentEntitlements() async` | `currentEntitlementsPublisher()` |
| `IntroOfferCheckable` | `isEligibleForIntroOffer(productID:) async` | `isEligibleForIntroOfferPublisher(productID:)` |
| `TransactionObservable` | `updates() -> AsyncStream` | `updatesPublisher()` |
| `TransactionCaching` | `all()`, `record()`, `reconcile()`, `clearAll()` | — |
| `StoreKitFlowLogging` | `log(_ event:)` | `isEnabled` (default: `true`, no-op setter) |
| `StoreObservable` | Full store surface | — |

### Models

| Type | Description |
|---|---|
| `StoreProduct` | Type-safe product wrapper — ID, name, price, type, offers |
| `PurchaseAttributes` | All `Product.PurchaseOption` values in one struct |
| `PurchaseOutcome` | Exhaustive typed result of a purchase call |
| `StoreKitFlowError` | Typed errors: `.productNotFound`, `.purchaseFailed(Error)`, `.unknown(Error)` |
| `CachedTransaction` | Persistent transaction record with delivery trail |
| `TransactionDeliveryEvent` | Single delivery event: date, source, path |
| `TransactionUpdate` | External event payload: productID, transactionID, reason |
| `IntroductoryOffer` | Introductory offer details: paymentMode, displayPrice, period |
| `PromotionalOffer` | Promotional offer details: id, displayName, paymentMode, displayPrice, period |
| `WinBackOffer` | Win-back offer details: id, paymentMode, displayPrice, period |
| `ProductType` | `.consumable` / `.nonConsumable` / `.autoRenewable` / `.nonRenewing` |
| `PaymentMode` | `.free` / `.payAsYouGo` / `.payUpFront` |
| `EntitlementStatus` | `.active` / `.expired` / `.revoked` |
| `CacheSource` | `.purchase` / `.renewal` / `.restore` / `.unfinished` |
| `TransactionDeliveryPath` | `.storePurchase` / `.transactionUpdates` / `.transactionUnfinished` / `.reconciliation` |
| `StoreLog` | Log entry wrapper: id, timestamp, event |
| `StoreLogEvent` | Enum of all loggable events with description, category, icon, isError, details |
| `StoreLogCategory` | `.productService` / `.purchaseFlow` / `.transactions` / `.entitlements` / `.restore` / `.cache` |

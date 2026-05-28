import SwiftUI
import StoreKit

struct SKProductViewScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore
    @State private var productStyle: ProductViewStyleOption = .regular
    @State private var iconBorder = false
    @State private var showLargeSheet = false

    @State private var loadedProduct: Product?
    @State private var loadError: String?

    @State private var purchaseStartLog: String?
    @State private var purchaseCompletionLog: String?

    @State private var refundTransactionID: UInt64?
    @State private var showRefundSheet = false
    @State private var refundResult: String?

    @State private var overlayPosition: OverlayPositionOption = .bottom
    @State private var showOverlay = false

    @State private var useAppAccountToken = false
    @State private var appAccountToken = UUID()
    @State private var purchaseQuantity = 1
    @State private var simulatesAskToBuy = false
    @State private var showPurchaseOptionsSheet = false

    @State private var loadedProducts: [Product] = []
    @State private var loadProductsError: String?
    @State private var entitlementStatus: String = "—"
    @State private var productDescriptionVisibility: Visibility = .automatic

    private let demoProductID = "com.storekitflow.demo.removeads"
    private let secondProductID = "com.storekitflow.demo.coins10"

    private var productIcon: some View {
        Image(systemName: "nosign")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .padding(12)
            .background(.red.gradient, in: RoundedRectangle(cornerRadius: 14))
    }

    @State private var selectedSection: ProductViewSection? = nil

    private enum ProductViewSection: String, CaseIterable, Identifiable {
        case dataBinding       = "Data Binding"
        case overlay           = "appStoreOverlay"
        case purchaseOptions   = "inAppPurchaseOptions"
        case refund            = "refundRequestSheet"
        case styleAndIcon      = "Style & Icon"
        case storeEvents       = "Store Events"
        var id: String { rawValue }
    }

    var body: some View {
        listWithModifiers
            .onInAppPurchaseStart { product in
                await MainActor.run { purchaseStartLog = "Started: \(product.displayName)" }
            }
            .onInAppPurchaseCompletion { product, result in
                await MainActor.run {
                    switch result {
                    case .success(let purchaseResult):
                        purchaseCompletionLog = "✓ \(product.displayName) — \(purchaseResult)"
                    case .failure(let error):
                        purchaseCompletionLog = "✗ \(product.displayName) — \(error.localizedDescription)"
                    }
                }
                await store.reconcile()
            }
            .storeProductTask(for: demoProductID) { taskState in
                switch taskState {
                case .success(let product): loadedProduct = product
                case .failure(let error):   loadError = error.localizedDescription
                case .loading:              break
                case .unavailable:          loadError = "Product unavailable"
                @unknown default:           break
                }
            }
            .storeProductsTask(for: [demoProductID, secondProductID]) { taskState in
                switch taskState {
                case .success(let loaded): loadedProducts = loaded.0
                case .failure(let error):  loadProductsError = error.localizedDescription
                case .loading:             break
                @unknown default:          break
                }
            }
            .currentEntitlementTask(for: demoProductID) { taskState in
                await MainActor.run {
                    switch taskState {
                    case .success(let verificationResult):
                        if let result = verificationResult {
                            switch result {
                            case .verified:   entitlementStatus = "Owned (verified)"
                            case .unverified: entitlementStatus = "Owned (unverified)"
                            }
                        } else {
                            entitlementStatus = "Not owned"
                        }
                    case .failure(let error): entitlementStatus = "Error: \(error.localizedDescription)"
                    case .loading:            entitlementStatus = "Loading…"
                    @unknown default:         break
                    }
                }
            }
            .refundRequestSheet(for: refundTransactionID ?? 0, isPresented: $showRefundSheet) { result in
                switch result {
                case .success(let status): refundResult = "Status: \(status)"
                case .failure(let error):  refundResult = "Error: \(error.localizedDescription)"
                }
            }
    }

    @ViewBuilder
    private var listWithModifiers: some View {
        theList
            #if os(iOS)
            .appStoreOverlay(isPresented: $showOverlay) {
                SKOverlay.AppConfiguration(appIdentifier: store.configuration.appStoreID ?? "1632168877", position: overlayPosition.skPosition)
            }
            #endif
    }

    @ViewBuilder
    private var theList: some View {
        List {
            if selectedSection == nil || selectedSection == .styleAndIcon    { styleSection }
            if selectedSection == nil || selectedSection == .storeEvents     { storeEventsSection }
            if selectedSection == nil || selectedSection == .purchaseOptions { purchaseOptionsSection }
            if selectedSection == nil || selectedSection == .refund          { refundSection }
            if selectedSection == nil || selectedSection == .overlay         { overlaySection }
            if selectedSection == nil || selectedSection == .dataBinding     { dataBindingSection }
        }
        .sheet(isPresented: $showLargeSheet) { largeSheet }
        .sheet(isPresented: $showPurchaseOptionsSheet) { purchaseOptionsSheet }
        .listSectionSpacing(12)
        .navigationTitle("ProductView")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) { sectionFilterBar }
    }

    private var sectionFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedSection == nil) { selectedSection = nil }
                ForEach(ProductViewSection.allCases) { section in
                    FilterChip(title: section.rawValue, isSelected: selectedSection == section) {
                        selectedSection = selectedSection == section ? nil : section
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    // MARK: - Style + Icon

    private var styleSection: some View {
        Section {
            Picker("productViewStyle", selection: $productStyle) {
                ForEach(ProductViewStyleOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("Controls the layout density — .regular, .compact, or .large")
            Toggle("productIconBorder()", isOn: $iconBorder)
            .hint("Applies Apple's standard rounded border to your custom icon view")
            Picker("productDescription", selection: $productDescriptionVisibility) {
                Text(".automatic").tag(Visibility.automatic)
                Text(".visible").tag(Visibility.visible)
                Text(".hidden").tag(Visibility.hidden)
            }
            .hint("Controls whether the product description text appears below the title")
            Group {
                switch productStyle {
                case .regular:
                    ProductView(id: demoProductID) {
                        productIcon.applyBorderIfNeeded(iconBorder)
                    }
                    .productViewStyle(.regular)
                    .productDescription(productDescriptionVisibility)
                case .compact:
                    ProductView(id: demoProductID) {
                        productIcon.applyBorderIfNeeded(iconBorder)
                    }
                    .productViewStyle(.compact)
                    .productDescription(productDescriptionVisibility)
                case .large:
                    Button { showLargeSheet = true } label: {
                        Label("Open .large ProductView", systemImage: "arrow.up.square")
                    }
                }
            }
        } header: {
            Label("Style & Icon", systemImage: "paintbrush")
        } footer: {
            InfoBox {
                InfoItem.group(".productViewStyle", variants: [
                    (".regular", "standard row with title, description, and price button — ideal inline in a list"),
                    (".compact", "dense single-line row — best for space-constrained layouts"),
                    (".large",   "prominent hero card — always present in a sheet")
                ])
                InfoItem.api(".productIconBorder()", "applies Apple's standard rounded-rectangle border to your custom icon view")
                InfoItem.group(".productDescription", variants: [
                    (".automatic", "system default — shows description when space allows"),
                    (".visible",   "always show the product description"),
                    (".hidden",    "always hide the product description")
                ])
            }
        }
    }

    private var largeSheetModifiers: [String] {
        var lines = ["ProductView(id: productID)"]
        lines.append("  .productViewStyle(.large)")
        if iconBorder { lines.append("  .productIconBorder()") }
        return lines
    }

    @ViewBuilder
    private var largeSheet: some View {
        PreviewSheet(title: "ProductView — .large", modifiers: largeSheetModifiers, showDismissButton: true) {
            VStack {
                Spacer()
                ProductView(id: demoProductID) {
                    productIcon.applyBorderIfNeeded(iconBorder)
                }
                .productViewStyle(.large)
                .padding(.horizontal)
                Spacer()
            }
        }
    }

    // MARK: - Store Events

    private var storeEventsSection: some View {
        Section {
            if let log = purchaseStartLog {
                LabeledContent("onInAppPurchaseStart", value: log)
            } else {
                Text("Tap a buy button above to trigger onInAppPurchaseStart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let log = purchaseCompletionLog {
                LabeledContent("onInAppPurchaseCompletion", value: log)
                    .lineLimit(3)
            } else {
                Text("Complete a purchase to trigger onInAppPurchaseCompletion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("Store Events", systemImage: "bell.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".onInAppPurchaseStart { product in … }", "async closure called the moment the user initiates a purchase — before the payment sheet appears")
                InfoItem.api(".onInAppPurchaseCompletion { product, result in … }", "async closure called after the purchase sheet is dismissed — result is Result<Product.PurchaseResult, Error>")
                InfoItem.note("Both modifiers bubble up the view hierarchy — attach them anywhere above your ProductView or StoreView.")
            }
        }
    }

    // MARK: - Purchase Options

    private var activePurchaseOptions: Set<Product.PurchaseOption> {
        var options: Set<Product.PurchaseOption> = []
        if useAppAccountToken { options.insert(.appAccountToken(appAccountToken)) }
        if purchaseQuantity > 1 { options.insert(.quantity(purchaseQuantity)) }
        if simulatesAskToBuy { options.insert(.simulatesAskToBuyInSandbox(true)) }
        return options
    }

    private var purchaseOptionsSection: some View {
        Section {
            Toggle("appAccountToken", isOn: Binding(
                get: { useAppAccountToken },
                set: { useAppAccountToken = $0; if $0 { appAccountToken = UUID() } }
            ))
            .hint("Links the purchase to an app-side account — appears in the transaction's appAccountToken field")
            if useAppAccountToken {
                LabeledContent("Token", value: appAccountToken.uuidString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Stepper("quantity: \(purchaseQuantity)", value: $purchaseQuantity, in: 1...10)
                .hint("Purchase multiple units — meaningful for consumables and non-renewing subscriptions")
            Toggle("simulatesAskToBuyInSandbox", isOn: $simulatesAskToBuy)
                .hint("Triggers the Ask to Buy parental approval flow in sandbox")
            Button { showPurchaseOptionsSheet = true } label: {
                Label("Open ProductView with Options", systemImage: "slider.horizontal.3")
            }
        } header: {
            Label("inAppPurchaseOptions", systemImage: "slider.horizontal.3")
        } footer: {
            InfoBox {
                InfoItem.api(".inAppPurchaseOptions { product in … }", "called before each purchase — return a Set<Product.PurchaseOption> to inject into the transaction")
                InfoItem.api(".appAccountToken(UUID)", "links the purchase to an app-side user account — appears in the transaction's appAccountToken field")
                InfoItem.api(".quantity(Int)", "purchase multiple units — only meaningful for consumables and non-renewing subscriptions")
                InfoItem.api(".simulatesAskToBuyInSandbox(Bool)", "triggers the Ask to Buy parental approval flow in sandbox — use to test deferred purchase handling")
                InfoItem.note("The closure receives the specific Product being purchased — you can vary options per product. Pass nil to clear any options ancestor views added.")
            }
        }
    }

    private var purchaseOptionsModifiers: [String] {
        var lines = ["ProductView(id: productID)"]
        lines.append("  .inAppPurchaseOptions { _ in options }")
        if useAppAccountToken   { lines.append("  // .appAccountToken(\(appAccountToken.uuidString.prefix(8))...)") }
        if purchaseQuantity > 1 { lines.append("  // .quantity(\(purchaseQuantity))") }
        if simulatesAskToBuy    { lines.append("  // .simulatesAskToBuyInSandbox(true)") }
        return lines
    }

    @ViewBuilder
    private var purchaseOptionsSheet: some View {
        PreviewSheet(title: "inAppPurchaseOptions", modifiers: purchaseOptionsModifiers, showDismissButton: true) {
            VStack {
                Spacer()
                ProductView(id: demoProductID) {
                    productIcon
                }
                .productViewStyle(.large)
                .padding(.horizontal)
                Spacer()
            }
            .inAppPurchaseOptions { _ in activePurchaseOptions }
        }
    }

    // MARK: - Refund

    private var refundSection: some View {
        Section {
            if let id = refundTransactionID {
                LabeledContent("Transaction ID", value: "\(id)")
            }
            Button("Show Refund Sheet") { showRefundSheet = true }
            if let result = refundResult {
                LabeledContent("Result", value: result)
            }
        } header: {
            Label("refundRequestSheet", systemImage: "arrow.uturn.backward.circle.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".refundRequestSheet(for: transactionID, isPresented:)", "presents Apple's system refund UI for the given transaction — user completes the refund flow inside the sheet")
                InfoItem.api("onDismiss: (Result<RefundRequestStatus, RefundRequestError>) -> ()", "called when the sheet is dismissed — check .success(.userCancelled) vs .success(.success) vs .failure")
                InfoItem.note("Requires a real Transaction.ID — unavailable in StoreKit Testing environment.")
            }
        }
        .onInAppPurchaseCompletion { _, result in
            if case .success(let purchaseResult) = result,
               case .success(let verificationResult) = purchaseResult {
                await MainActor.run { refundTransactionID = (try? verificationResult.payloadValue)?.id }
            }
        }
    }

    // MARK: - Data Binding

    private var dataBindingSection: some View {
        Section {
            if let product = loadedProduct {
                LabeledContent("storeProductTask", value: product.displayName)
                LabeledContent("displayPrice", value: product.displayPrice)
            } else if let error = loadError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            } else {
                HStack {
                    ProgressView()
                    Text("storeProductTask loading…")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            Divider()
            if loadedProducts.isEmpty && loadProductsError == nil {
                HStack {
                    ProgressView()
                    Text("storeProductsTask loading…")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            } else if let error = loadProductsError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            } else {
                ForEach(loadedProducts, id: \.id) { product in
                    LabeledContent("storeProductsTask", value: product.displayName)
                }
            }
            Divider()
            LabeledContent("currentEntitlementTask", value: entitlementStatus)
        } header: {
            Label("Data Binding", systemImage: "bolt.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".storeProductTask(for: productID)", "loads a single product declaratively — fires on appear and on StoreKit updates")
                InfoItem.api(".storeProductsTask(for: [ids])", "loads a collection of products — use when you need multiple products loaded and kept in sync")
                InfoItem.api(".currentEntitlementTask(for: productID)", "fires whenever the user's entitlement for a product changes — nil for consumables")
                InfoItem.note("All three task modifiers restart automatically when their input parameter changes.")
                InfoItem.availability("iOS 17+")
            }
        }
    }

    // MARK: - App Store Overlay

    private var overlaySection: some View {
        Section {
            Picker("Position", selection: $overlayPosition) {
                ForEach(OverlayPositionOption.allCases) { Text($0.label).tag($0) }
            }
            .hint(".bottom anchors to the bottom edge, .bottomRaised lifts above the tab bar")
            Button { showOverlay = true } label: {
                Label("Show App Store Overlay", systemImage: "square.stack.fill")
            }
        } header: {
            Label("appStoreOverlay", systemImage: "square.stack.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".appStoreOverlay(isPresented:configuration:)", "presents a non-modal App Store overlay that lets users download or open another app without leaving your app")
                InfoItem.api("SKOverlay.AppConfiguration(appIdentifier:position:)", "configure which app to promote and where the overlay appears")
                InfoItem.api(".bottom", "overlay anchored to the bottom edge")
                InfoItem.api(".bottomRaised", "overlay raised above the bottom — useful when a tab bar is present")
            }
        }
    }
}

extension View {
    @ViewBuilder
    func applyBorderIfNeeded(_ apply: Bool) -> some View {
        if apply { self.productIconBorder() } else { self }
    }
}


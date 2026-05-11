import SwiftUI
import StoreKitFlow
import StoreKit

struct SKProductViewScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore
    @State private var productStyle: ProductViewStyleOption = .regular
    @State private var iconBorder = false
    @State private var showLargeSheet = false

    // storeProductTask
    @State private var loadedProduct: Product?
    @State private var loadError: String?

    // Store Events
    @State private var purchaseStartLog: String?
    @State private var purchaseCompletionLog: String?

    // Refund
    @State private var refundTransactionID: UInt64?
    @State private var showRefundSheet = false
    @State private var refundResult: String?

    // App Store Overlay
    @State private var overlayPosition: OverlayPositionOption = .bottom
    @State private var showOverlay = false

    private let demoProductID = "com.storekitflow.demo.removeads"

    private var productIcon: some View {
        Image(systemName: "nosign")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .padding(12)
            .background(.red.gradient, in: RoundedRectangle(cornerRadius: 14))
    }

    var body: some View {
        List {
            styleSection
            storeEventsSection
            refundSection
            overlaySection
            dataBindingSection
        }
        .listSectionSpacing(12)
        .navigationTitle("ProductView")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLargeSheet) { largeSheet }
        .appStoreOverlay(isPresented: $showOverlay) {
            SKOverlay.AppConfiguration(appIdentifier: store.configuration.appStoreID ?? "1632168877", position: overlayPosition.skPosition)
        }
        .refundRequestSheet(for: refundTransactionID ?? 0, isPresented: $showRefundSheet) { result in
            switch result {
            case .success(let status): refundResult = "Status: \(status)"
            case .failure(let error):  refundResult = "Error: \(error.localizedDescription)"
            }
        }
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
    }

    // MARK: - Style + Icon

    private var styleSection: some View {
        Section {
            Picker("productViewStyle", selection: $productStyle) {
                ForEach(ProductViewStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("productIconBorder()", isOn: $iconBorder)

            Group {
                switch productStyle {
                case .regular:
                    ProductView(id: demoProductID) {
                        productIcon.applyBorderIfNeeded(iconBorder)
                    }
                    .productViewStyle(.regular)
                case .compact:
                    ProductView(id: demoProductID) {
                        productIcon.applyBorderIfNeeded(iconBorder)
                    }
                    .productViewStyle(.compact)
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
                InfoItem.api(".productViewStyle(.regular)", "standard row with title, description, and price button — ideal inline in a list")
                InfoItem.api(".productViewStyle(.compact)", "dense single-line row — best for space-constrained layouts")
                InfoItem.api(".productViewStyle(.large)", "prominent hero card — always present in a sheet")
                InfoItem.api(".productIconBorder()", "applies Apple's standard rounded-rectangle border to your custom icon view")
            }
        }
    }

    @ViewBuilder
    private var largeSheet: some View {
        NavigationStack {
            VStack {
                Spacer()
                ProductView(id: demoProductID) {
                    productIcon.applyBorderIfNeeded(iconBorder)
                }
                .productViewStyle(.large)
                .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("ProductView — .large")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showLargeSheet = false }
                }
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
                LabeledContent("displayName", value: product.displayName)
                LabeledContent("displayPrice", value: product.displayPrice)
                LabeledContent("type", value: product.type.rawValue)
            } else if let error = loadError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            } else {
                HStack {
                    ProgressView()
                    Text("Loading product…")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Label("storeProductTask", systemImage: "bolt.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".storeProductTask(for: productID)", "declarative modifier that loads a single product without manual async code — fires on appear and on StoreKit updates")
                InfoItem.api("result: Result<Product, Error>", "closure receives .success(product) or .failure(error) — update local @State to drive UI")
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

private enum OverlayPositionOption: String, CaseIterable, Identifiable {
    case bottom, bottomRaised
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
    var skPosition: SKOverlay.Position {
        switch self {
        case .bottom:       return .bottom
        case .bottomRaised: return .bottomRaised
        }
    }
}

#Preview {
    NavigationStack {
        SKProductViewScreen()
    }
}

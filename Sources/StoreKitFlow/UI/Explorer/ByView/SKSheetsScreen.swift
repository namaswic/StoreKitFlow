import SwiftUI
import StoreKit

#if os(iOS)
struct SKSheetsScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore

    @State private var showManageSheet = false
    @State private var showOfferCodeSheet = false

    @State private var refundTransactionID: UInt64?
    @State private var showRefundSheet = false
    @State private var refundResult: String?

    @State private var overlayPosition: OverlayPositionOption = .bottom
    @State private var showOverlay = false

    @State private var showMerchandising = false
    @State private var merchandisingResult: String?

    @State private var selectedSection: SheetsSection? = nil

    private enum SheetsSection: String, CaseIterable, Identifiable {
        case appStoreMerchandising  = "appStoreMerchandising"
        case appStoreOverlay        = "appStoreOverlay"
        case manageSubscriptions    = "manageSubscriptionsSheet"
        case offerCodeRedemption    = "offerCodeRedemption"
        case refundRequest          = "refundRequestSheet"
        var id: String { rawValue }
    }

    var body: some View {
        List {
            if selectedSection == nil || selectedSection == .manageSubscriptions  { manageSection }
            if selectedSection == nil || selectedSection == .offerCodeRedemption  { offerCodeSection }
            if selectedSection == nil || selectedSection == .refundRequest        { refundSection }
            if selectedSection == nil || selectedSection == .appStoreOverlay      { overlaySection }
            if selectedSection == nil || selectedSection == .appStoreMerchandising { merchandisingSection }
        }
        .manageSubscriptionsSheet(isPresented: $showManageSheet)
        .offerCodeRedemption(isPresented: $showOfferCodeSheet)
        .refundRequestSheet(for: refundTransactionID ?? 0, isPresented: $showRefundSheet) { result in
            switch result {
            case .success(let status): refundResult = "Status: \(status)"
            case .failure(let error):  refundResult = "Error: \(error.localizedDescription)"
            }
        }
        .appStoreOverlay(isPresented: $showOverlay) {
            SKOverlay.AppConfiguration(
                appIdentifier: store.configuration.appStoreID ?? "1632168877",
                position: overlayPosition.skPosition
            )
        }
        .modifier(MerchandisingModifier(isPresented: $showMerchandising, result: $merchandisingResult))
        .listSectionSpacing(12)
        .navigationTitle("Sheets & Overlays")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) { sectionFilterBar }
    }

    private var sectionFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedSection == nil) { selectedSection = nil }
                ForEach(SheetsSection.allCases) { section in
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

    // MARK: - manageSubscriptionsSheet

    private var manageSection: some View {
        Section {
            Button { showManageSheet = true } label: {
                Label("Open Manage Subscriptions", systemImage: "person.crop.circle.badge.checkmark")
            }
        } header: {
            Label("manageSubscriptionsSheet", systemImage: "person.crop.circle.badge.checkmark")
        } footer: {
            InfoBox {
                InfoItem.api(".manageSubscriptionsSheet(isPresented:)", "presents Apple's system subscription management UI — users can cancel, upgrade, or downgrade without leaving your app")
                InfoItem.note("Attach this modifier anywhere in the view hierarchy — not tied to SubscriptionStoreView.")
            }
        }
    }

    // MARK: - offerCodeRedemption

    private var offerCodeSection: some View {
        Section {
            Button { showOfferCodeSheet = true } label: {
                Label("Redeem Offer Code", systemImage: "ticket.fill")
            }
        } header: {
            Label("offerCodeRedemption", systemImage: "ticket.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".offerCodeRedemption(isPresented:)", "presents Apple's system UI for entering a promo or offer code — redeems it automatically on confirmation")
                InfoItem.note("Attach this modifier anywhere in the view hierarchy — works independently of any store view.")
            }
        }
    }

    // MARK: - refundRequestSheet

    private var refundSection: some View {
        Section {
            if let id = refundTransactionID {
                LabeledContent("Transaction ID", value: "\(id)")
            } else {
                Text("No transaction ID — complete a purchase in ProductView or SubscriptionStoreView first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button("Show Refund Sheet") { showRefundSheet = true }
                .disabled(refundTransactionID == nil)
            if let result = refundResult {
                LabeledContent("Result", value: result)
            }
        } header: {
            Label("refundRequestSheet", systemImage: "arrow.uturn.backward.circle.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".refundRequestSheet(for: transactionID, isPresented:)", "presents Apple's refund request UI for a specific transaction")
                InfoItem.api("onDismiss result", "Result<Transaction.RefundRequestStatus, Transaction.RefundRequestError>")
                InfoItem.note("Requires a real Transaction.ID — capture one from .onInAppPurchaseCompletion after a purchase.")
            }
        }
    }

    // MARK: - appStoreMerchandising

    private var merchandisingSection: some View {
        Section {
            if #available(iOS 26.0, *) {
                Button { showMerchandising = true } label: {
                    Label("Show App Store Merchandising", systemImage: "storefront.fill")
                }
                if let result = merchandisingResult {
                    LabeledContent("Result", value: result)
                }
            } else {
                ContentUnavailableView(
                    "Requires iOS 26",
                    systemImage: "exclamationmark.triangle",
                    description: Text("appStoreMerchandising requires iOS 26 or later.")
                )
                .listRowBackground(Color.clear)
            }
        } header: {
            Label("appStoreMerchandising", systemImage: "storefront.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".appStoreMerchandising(isPresented:kind:onDismiss:)", "iOS 26+ (iPhone only) — presents an App Store merchandising sheet for a specific kind of in-app purchase")
                InfoItem.api("onDismiss", "Result<AppStoreMerchandisingKind.PresentationResult, Error> — reports whether the user took action")
                InfoItem.availability("iOS 26+, iPhone only")
            }
        }
    }

    // MARK: - appStoreOverlay

    private var overlaySection: some View {
        Section {
            Picker("Position", selection: $overlayPosition) {
                ForEach(OverlayPositionOption.allCases) { Text($0.label).tag($0) }
            }
            .hint(".bottom anchors to the edge, .bottomRaised lifts above the tab bar")
            Button { showOverlay = true } label: {
                Label("Show App Store Overlay", systemImage: "square.stack.fill")
            }
        } header: {
            Label("appStoreOverlay", systemImage: "square.stack.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".appStoreOverlay(isPresented:configuration:)", "non-modal overlay promoting another app — user can download or open without leaving your app")
                InfoItem.api("SKOverlay.AppConfiguration(appIdentifier:position:)", "configure which app to promote and where the overlay anchors")
                InfoItem.group("position", variants: [
                    (".bottom",      "anchored to the bottom edge"),
                    (".bottomRaised","raised above the bottom — use when a tab bar is visible")
                ])
            }
        }
    }
}

private struct MerchandisingModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var result: String?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.appStoreMerchandising(isPresented: $isPresented, kind: .subscriptionBundle("763D6759")) { outcome in
                await MainActor.run {
                    switch outcome {
                    case .success(let r): result = "\(r)"
                    case .failure(let e): result = "Error: \(e.localizedDescription)"
                    }
                }
            }
        } else {
            content
        }
    }
}
#endif


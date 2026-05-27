import SwiftUI
import StoreKit

struct SKStoreViewScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore
    @State private var storeStyle: ProductViewStyleOption = .regular
    @State private var showRestorePurchases = true
    @State private var showRedeemCode = false
    @State private var showPolicies = true
    @State private var showSheet = false
    @State private var showOfferCodeSheet = false
    @State private var overlayPosition: OverlayPositionOption = .bottom
    @State private var showOverlay = false

    private let storeIDs = [
        "com.storekitflow.demo.coins10",
        "com.storekitflow.demo.removeads",
        "com.storekitflow.demo.themes",
        "com.storekitflow.demo.pass.30days"
    ]

    @State private var selectedSection: StoreViewSection? = nil

    private enum StoreViewSection: String, CaseIterable, Identifiable {
        case productViewStyle    = "productViewStyle"
        case sheetsAndOverlays   = "Sheets & Overlays"
        case storeButton         = "storeButton"
        var id: String { rawValue }
    }

    var body: some View {
        List {
            if selectedSection == nil || selectedSection == .productViewStyle  { styleSection }
            if selectedSection == nil || selectedSection == .storeButton       { buttonsSection }
            if selectedSection == nil || selectedSection == .sheetsAndOverlays { sheetsAndOverlaysSection }
        }
        .listSectionSpacing(12)
        .navigationTitle("StoreView")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedSection == nil) { selectedSection = nil }
                    ForEach(StoreViewSection.allCases) { section in
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
        .sheet(isPresented: $showSheet) { storeSheet }
        .offerCodeRedemption(isPresented: $showOfferCodeSheet)
        .appStoreOverlay(isPresented: $showOverlay) {
            SKOverlay.AppConfiguration(appIdentifier: store.configuration.appStoreID ?? "1632168877", position: overlayPosition.skPosition)
        }
    }

    // MARK: - Style

    private var styleSection: some View {
        Section {
            Picker("productViewStyle", selection: $storeStyle) {
                ForEach(ProductViewStyleOption.allCases) { Text($0.label).tag($0) }
            }
        } header: {
            Label("productViewStyle", systemImage: "paintbrush")
        } footer: {
            InfoBox {
                InfoItem.note("StoreView always presents as a sheet — it includes its own dismiss button.")
                InfoItem.group(".productViewStyle", variants: [
                    (".regular", "standard row per product — default layout"),
                    (".compact", "dense single-line rows — fits more products on screen"),
                    (".large",   "hero cards — one prominent card per product")
                ])
                InfoItem.api(".productIconBorder()", "pass a custom icon view to StoreView — add .productIconBorder() on the icon to apply Apple's rounded border")
            }
        }
    }

    // MARK: - Accessory Buttons

    private var buttonsSection: some View {
        Section {
            Toggle("Restore Purchases", isOn: $showRestorePurchases)
            Toggle("Redeem Code", isOn: $showRedeemCode)
            Toggle("Policies", isOn: $showPolicies)
            Button { showSheet = true } label: {
                Label("Preview StoreView", systemImage: "bag.fill")
            }
        } header: {
            Label("storeButton", systemImage: "ellipsis.circle.fill")
        } footer: {
            InfoBox {
                InfoItem.group(".storeButton", variants: [
                    (".visible, for: .restorePurchases", "shows a 'Restore Purchases' button below the product list"),
                    (".visible, for: .redeemCode",       "shows a 'Redeem Code' button for promo codes"),
                    (".visible, for: .policies",         "shows links to your privacy policy and terms of service"),
                    (".hidden, for:",                    "explicitly hides a button — useful to override system defaults")
                ])
            }
        }
    }

    // MARK: - Sheets & Overlays

    private var sheetsAndOverlaysSection: some View {
        Section {
            Button { showOfferCodeSheet = true } label: {
                Label("Redeem Offer Code", systemImage: "ticket.fill")
            }
            Picker("Overlay position", selection: $overlayPosition) {
                ForEach(OverlayPositionOption.allCases) { Text($0.label).tag($0) }
            }
            Button { showOverlay = true } label: {
                Label("Show App Store Overlay", systemImage: "square.stack.fill")
            }
        } header: {
            Label("Sheets & Overlays", systemImage: "rectangle.stack.badge.plus")
        } footer: {
            InfoBox {
                InfoItem.api(".offerCodeRedemption(isPresented:)", "presents Apple's system UI for entering a promo or offer code — redeems it automatically on confirmation")
                InfoItem.api(".appStoreOverlay(isPresented:configuration:)", "non-modal overlay that lets users download or open another app without leaving yours")
                InfoItem.api("SKOverlay.AppConfiguration(appIdentifier:position:)", "configure the app to promote and overlay anchor position")
                InfoItem.api(".bottom", "anchored to the bottom edge")
                InfoItem.api(".bottomRaised", "raised above bottom — use when a tab bar is visible")
            }
        }
    }

    // MARK: - Sheet

    @ViewBuilder
    private var storeSheet: some View {
        Group {
            switch storeStyle {
            case .large:   StoreView(ids: storeIDs).productViewStyle(.large)
            case .regular: StoreView(ids: storeIDs).productViewStyle(.regular)
            case .compact: StoreView(ids: storeIDs).productViewStyle(.compact)
            }
        }
        .storeButton(showRestorePurchases ? .visible : .hidden, for: .restorePurchases)
        .storeButton(showRedeemCode ? .visible : .hidden, for: .redeemCode)
        .storeButton(showPolicies ? .visible : .hidden, for: .policies)
    }
}

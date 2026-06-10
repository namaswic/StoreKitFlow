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
    @State private var showCompositionSheet = false
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
        case composition         = "Composition"
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
            if selectedSection == nil || selectedSection == .composition       { compositionSection }
        }
        .sheet(isPresented: $showSheet) { storeSheet }
        .sheet(isPresented: $showCompositionSheet) { compositionSheet }
        .listSectionSpacingCompact()
        .navigationTitle("StoreView")
        .inlineNavigationTitle()
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
        .offerCodeRedemption(isPresented: $showOfferCodeSheet)
        #if os(iOS)
        .appStoreOverlay(isPresented: $showOverlay) {
            SKOverlay.AppConfiguration(appIdentifier: store.configuration.appStoreID ?? "1632168877", position: overlayPosition.skPosition)
        }
        #endif
    }

    // MARK: - Style

    private var styleSection: some View {
        Section {
            Picker("productViewStyle", selection: $storeStyle) {
                ForEach(ProductViewStyleOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("Controls row density across all products in the StoreView")
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
                .hint(".storeButton(.visible, for: .restorePurchases)")
            Toggle("Redeem Code", isOn: $showRedeemCode)
                .hint(".storeButton(.visible, for: .redeemCode)")
            Toggle("Policies", isOn: $showPolicies)
                .hint(".storeButton(.visible, for: .policies)")
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
            .hint(".bottom anchors to the edge, .bottomRaised lifts above the tab bar")
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

    // MARK: - Composition (iOS 18+)

    private var compositionSection: some View {
        Section {
            if #available(iOS 18.0, *) {
                Button { showCompositionSheet = true } label: {
                    Label("Preview StoreContent Layout", systemImage: "square.stack.3d.up.fill")
                }
            } else {
                ContentUnavailableView(
                    "Requires iOS 18",
                    systemImage: "exclamationmark.triangle",
                    description: Text("StoreContent and @StoreContentBuilder require iOS 18 or later.")
                )
                .listRowBackground(Color.clear)
            }
        } header: {
            Label("Composition", systemImage: "square.stack.3d.up.fill")
        } footer: {
            InfoBox {
                InfoItem.api("StoreContent", "declarative descriptor for custom store layouts — defines what products and sections appear in a StoreView")
                InfoItem.api("@StoreContentBuilder", "result builder that composes multiple StoreContent values using declarative block syntax")
                InfoItem.note("Use @StoreContentBuilder to build a custom product listing by declaring which product IDs to show and how to group them.")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var compositionSheet: some View {
        if #available(iOS 18.0, *) {
            StoreView(ids: storeIDs) { _ in
                Image(systemName: "bag.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.indigo.gradient, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Sheet

    private var storeSheetModifiers: [String] {
        var lines = ["StoreView(ids: productIDs)"]
        lines.append("  .productViewStyle(.\(storeStyle.rawValue))")
        if showRestorePurchases { lines.append("  .storeButton(.visible, for: .restorePurchases)") }
        if showRedeemCode       { lines.append("  .storeButton(.visible, for: .redeemCode)") }
        if showPolicies         { lines.append("  .storeButton(.visible, for: .policies)") }
        return lines
    }

    @ViewBuilder
    private func storeViewWithStyle(_ style: ProductViewStyleOption) -> some View {
        Group {
            switch style {
            case .large:   StoreView(ids: storeIDs).productViewStyle(.large)
            case .regular: StoreView(ids: storeIDs).productViewStyle(.regular)
            case .compact: StoreView(ids: storeIDs).productViewStyle(.compact)
            }
        }
        .storeButton(showRestorePurchases ? .visible : .hidden, for: .restorePurchases)
        #if os(iOS)
        .storeButton(showRedeemCode ? .visible : .hidden, for: .redeemCode)
        #endif
        .storeButton(showPolicies ? .visible : .hidden, for: .policies)
    }

    @ViewBuilder
    private var storeSheet: some View {
        PreviewSheet(
            title: "StoreView",
            modifiers: storeSheetModifiers,
            variants: [
                PreviewSheetVariant(
                    label: ".regular",
                    modifiers: ["StoreView(ids: [...])", "  .productViewStyle(.regular)"],
                    content: AnyView(storeViewWithStyle(.regular))
                ),
                PreviewSheetVariant(
                    label: ".compact",
                    modifiers: ["StoreView(ids: [...])", "  .productViewStyle(.compact)"],
                    content: AnyView(storeViewWithStyle(.compact))
                ),
                PreviewSheetVariant(
                    label: ".large",
                    modifiers: ["StoreView(ids: [...])", "  .productViewStyle(.large)"],
                    content: AnyView(storeViewWithStyle(.large))
                ),
            ],
            showDismissButton: true
        ) { EmptyView() }
    }
}

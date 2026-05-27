import SwiftUI
import StoreKit

struct SKViewsDemoScreen: View {
    // All sheet state lives on the stable root view — never recreated by List
    @State private var productStyle: ProductViewStyleOption = .regular
    @State private var productIconBorder = false
    @State private var showProductSheet = false

    @State private var storeStyle: ProductViewStyleOption = .regular
    @State private var showStoreSheet = false

    @State private var subscriptionControlStyle: SubscriptionControlStyleOption = .prominentPicker
    @State private var showSubscriptionHeader = true
    @State private var showSubscriptionSheet = false

    @State private var offerStyle: SubscriptionOfferStyleOption = .automatic
    @State private var showOfferSheet = false

    private let groupID = "763D6759"
    private let storeIDs = [
        "com.storekitflow.demo.coins10",
        "com.storekitflow.demo.removeads",
        "com.storekitflow.demo.themes",
        "com.storekitflow.demo.pass.30days"
    ]

    @State private var selectedSection: ViewsSection? = nil

    private enum ViewsSection: String, CaseIterable, Identifiable {
        case productView        = "ProductView"
        case storeView          = "StoreView"
        case subscriptionStore  = "SubscriptionStoreView"
        case subscriptionOffer  = "SubscriptionOfferView"
        var id: String { rawValue }
    }

    var body: some View {
        List {
            if selectedSection == nil || selectedSection == .productView  { productViewSection }
            if selectedSection == nil || selectedSection == .storeView    { storeViewSection }
            if selectedSection == nil || selectedSection == .subscriptionStore { subscriptionStoreViewSection }
            if selectedSection == nil || selectedSection == .subscriptionOffer { subscriptionOfferViewSection }
        }
        .listSectionSpacing(12)
        .navigationTitle("Views")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) { sectionFilterBar }
        .sheet(isPresented: $showProductSheet) { productSheet }
        .sheet(isPresented: $showStoreSheet) { storeSheet }
        .sheet(isPresented: $showSubscriptionSheet) { subscriptionSheet }
        .sheet(isPresented: $showOfferSheet) { offerSheet }
    }

    private var sectionFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedSection == nil) { selectedSection = nil }
                ForEach(ViewsSection.allCases) { section in
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

    // MARK: - ProductView

    private var productViewSection: some View {
        Section {
            Picker("productViewStyle", selection: $productStyle) {
                ForEach(ProductViewStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("productIconBorder()", isOn: $productIconBorder)

            switch productStyle {
            case .regular:
                ProductView(id: "com.storekitflow.demo.removeads") {
                    productIcon.applyBorderIfNeeded(productIconBorder)
                }
                .productViewStyle(.regular)
            case .compact:
                ProductView(id: "com.storekitflow.demo.removeads") {
                    productIcon.applyBorderIfNeeded(productIconBorder)
                }
                .productViewStyle(.compact)
            case .large:
                Button { showProductSheet = true } label: {
                    Label("Open .large ProductView", systemImage: "arrow.up.square")
                }
            }
        } header: {
            Label("ProductView", systemImage: "cube.box.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".productViewStyle(.regular)", "standard row — shown inline in a list")
                InfoItem.api(".productViewStyle(.compact)", "dense row — great for space-constrained layouts")
                InfoItem.api(".productViewStyle(.large)", "prominent card — present in a sheet")
                InfoItem.api(".productIconBorder()", "applies Apple's standard rounded border to custom icons")
            }
        }
    }

    private var productIcon: some View {
        Image(systemName: "nosign")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .padding(12)
            .background(.red.gradient, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var productSheet: some View {
        NavigationStack {
            VStack {
                Spacer()
                ProductView(id: "com.storekitflow.demo.removeads") {
                    productIcon.applyBorderIfNeeded(productIconBorder)
                }
                .productViewStyle(.large)
                .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("ProductView — .large")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showProductSheet = false }
                }
            }
        }
    }

    // MARK: - StoreView

    private var storeViewSection: some View {
        Section {
            Picker("productViewStyle", selection: $storeStyle) {
                ForEach(ProductViewStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Button { showStoreSheet = true } label: {
                Label("Open StoreView", systemImage: "bag.fill")
            }
        } header: {
            Label("StoreView", systemImage: "bag.fill")
        } footer: {
            InfoBox {
                InfoItem.note("Always present as a .sheet — StoreView includes its own dismiss button")
                InfoItem.api(".productViewStyle(.large / .regular / .compact)", "controls row density and layout")
            }
        }
    }

    @ViewBuilder
    private var storeSheet: some View {
        switch storeStyle {
        case .large:   StoreView(ids: storeIDs).productViewStyle(.large)
        case .regular: StoreView(ids: storeIDs).productViewStyle(.regular)
        case .compact: StoreView(ids: storeIDs).productViewStyle(.compact)
        }
    }

    // MARK: - SubscriptionStoreView

    private var subscriptionStoreViewSection: some View {
        Section {
            Picker("subscriptionStoreControlStyle", selection: $subscriptionControlStyle) {
                ForEach(SubscriptionControlStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Custom marketing header", isOn: $showSubscriptionHeader)
            Button { showSubscriptionSheet = true } label: {
                Label("Open SubscriptionStoreView", systemImage: "repeat.circle.fill")
            }
        } header: {
            Label("SubscriptionStoreView", systemImage: "repeat.circle.fill")
        } footer: {
            InfoBox {
                InfoItem.note("Always present as a .sheet — manages its own dismiss button")
                InfoItem.api(".subscriptionStoreControlStyle()", ".buttons / .picker / .prominentPicker / .compactPicker")
                InfoItem.api("marketingContent:", "custom header view above the plan list")
                InfoItem.api(".subscriptionStorePolicyDestination(url:for:)", "links for privacy policy and terms of service")
            }
        }
    }

    @ViewBuilder
    private var subscriptionSheet: some View {
        let header = { AnyView(showSubscriptionHeader ? AnyView(paywallHeader) : AnyView(EmptyView())) }
        if #available(iOS 26.0, *) {
            switch subscriptionControlStyle {
            case .buttons:
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                    .subscriptionStoreControlStyle(.buttons)
            case .picker:
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                    .subscriptionStoreControlStyle(.picker)
            case .prominentPicker:
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                    .subscriptionStoreControlStyle(.prominentPicker)
            case .compactPicker:
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                    .subscriptionStoreControlStyle(.compactPicker)
            }
        } else {
            switch subscriptionControlStyle {
            case .buttons:
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                    .subscriptionStoreControlStyle(.buttons)
            case .picker, .prominentPicker, .compactPicker:
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                    .subscriptionStoreControlStyle(.prominentPicker)
            }
        }
    }

    private var paywallHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundStyle(.purple)
            Text("Go Pro")
                .font(.largeTitle.bold())
            Text("Unlimited projects, priority support, and early access to every new feature.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 32)
    }

    // MARK: - SubscriptionOfferView

    private var subscriptionOfferViewSection: some View {
        Section {
            if #available(iOS 26.0, *) {
                Picker("subscriptionOfferViewStyle", selection: $offerStyle) {
                    ForEach(SubscriptionOfferStyleOption.allCases) { Text($0.label).tag($0) }
                }
                Button { showOfferSheet = true } label: {
                    Label("Open SubscriptionOfferView", systemImage: "tag.fill")
                }
            } else {
                ContentUnavailableView(
                    "Requires iOS 26",
                    systemImage: "exclamationmark.triangle",
                    description: Text("SubscriptionOfferView is available on iOS 26 and later.")
                )
                .listRowBackground(Color.clear)
            }
        } header: {
            Label("SubscriptionOfferView", systemImage: "tag.fill")
        } footer: {
            InfoBox {
                InfoItem.note("Present as a .sheet for intro, promo, or win-back offers")
                InfoItem.api(".subscriptionOfferViewStyle(.automatic)", "system default layout")
                InfoItem.api(".subscriptionOfferViewStyle(.compact)", "smaller card layout")
                InfoItem.availability("iOS 26+")
            }
        }
    }

    @ViewBuilder
    private var offerSheet: some View {
        if #available(iOS 26.0, *) {
            switch offerStyle {
            case .automatic:
                SubscriptionOfferView(groupID: groupID, visibleRelationship: .all)
            case .compact:
                SubscriptionOfferView(groupID: groupID, visibleRelationship: .all)
                    .subscriptionOfferViewStyle(.compact)
            }
        } else {
            ContentUnavailableView(
                "Requires iOS 26",
                systemImage: "exclamationmark.triangle",
                description: Text("SubscriptionOfferView is available on iOS 26 and later.")
            )
        }
    }
}

// MARK: - Helpers

extension View {
    @ViewBuilder
    func applyBorderIfNeeded(_ apply: Bool) -> some View {
        if apply { self.productIconBorder() } else { self }
    }
}

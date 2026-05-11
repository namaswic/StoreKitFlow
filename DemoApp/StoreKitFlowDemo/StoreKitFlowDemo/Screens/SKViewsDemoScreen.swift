import SwiftUI
import StoreKit

struct SKViewsDemoScreen: View {
    var body: some View {
        List {
            ProductViewSection()
            StoreViewSection()
            SubscriptionStoreViewSection()
            SubscriptionOfferViewSection()
        }
        .listSectionSpacing(12)
        .navigationTitle("Views")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ProductView
// .compact and .regular are inline row components — live in the list.
// .large is a prominent card — presented in a sheet.

private struct ProductViewSection: View {
    @State private var style: ProductViewStyleOption = .regular
    @State private var showIconBorder = false
    @State private var showLargeSheet = false

    var body: some View {
        Section {
            Picker("productViewStyle", selection: $style) {
                ForEach(ProductViewStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("productIconBorder()", isOn: $showIconBorder)

            switch style {
            case .regular:
                ProductView(id: "com.storekitflow.demo.removeads") {
                    iconView.applyBorderIfNeeded(showIconBorder)
                }
                .productViewStyle(.regular)

            case .compact:
                ProductView(id: "com.storekitflow.demo.removeads") {
                    iconView.applyBorderIfNeeded(showIconBorder)
                }
                .productViewStyle(.compact)

            case .large:
                Button {
                    showLargeSheet = true
                } label: {
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
        .sheet(isPresented: $showLargeSheet) {
            NavigationStack {
                VStack {
                    Spacer()
                    ProductView(id: "com.storekitflow.demo.removeads") {
                        iconView.applyBorderIfNeeded(showIconBorder)
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
    }

    private var iconView: some View {
        Image(systemName: "nosign")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .padding(12)
            .background(.red.gradient, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - StoreView
// Always a sheet — StoreView manages its own dismiss button.

private struct StoreViewSection: View {
    @State private var style: ProductViewStyleOption = .regular
    @State private var showSheet = false

    private let ids = [
        "com.storekitflow.demo.coins10",
        "com.storekitflow.demo.removeads",
        "com.storekitflow.demo.themes",
        "com.storekitflow.demo.pass.30days"
    ]

    var body: some View {
        Section {
            Picker("productViewStyle", selection: $style) {
                ForEach(ProductViewStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Button {
                showSheet = true
            } label: {
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
        .sheet(isPresented: $showSheet) {
            switch style {
            case .large:   StoreView(ids: ids).productViewStyle(.large)
            case .regular: StoreView(ids: ids).productViewStyle(.regular)
            case .compact: StoreView(ids: ids).productViewStyle(.compact)
            }
        }
    }
}

// MARK: - SubscriptionStoreView
// The standard paywall pattern — always a sheet. Manages its own dismiss.

private struct SubscriptionStoreViewSection: View {
    @State private var controlStyle: SubscriptionControlStyleOption = .prominentPicker
    @State private var showCustomHeader = true
    @State private var showSheet = false

    private let groupID = "763D6759"

    var body: some View {
        Section {
            Picker("subscriptionStoreControlStyle", selection: $controlStyle) {
                ForEach(SubscriptionControlStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Custom marketing header", isOn: $showCustomHeader)
            Button {
                showSheet = true
            } label: {
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
        .sheet(isPresented: $showSheet) {
            subscriptionView
        }
    }

    @ViewBuilder
    private var subscriptionView: some View {
        let header: () -> some View = {
            AnyView(showCustomHeader ? AnyView(paywallHeader) : AnyView(EmptyView()))
        }
        switch controlStyle {
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
}

// MARK: - SubscriptionOfferView
// A targeted offer card — always a sheet. iOS 18+.

private struct SubscriptionOfferViewSection: View {
    @State private var offerStyle: SubscriptionOfferStyleOption = .automatic
    @State private var showSheet = false

    var body: some View {
        Section {
            Picker("subscriptionOfferViewStyle", selection: $offerStyle) {
                ForEach(SubscriptionOfferStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Button {
                showSheet = true
            } label: {
                Label("Open SubscriptionOfferView", systemImage: "tag.fill")
            }
        } header: {
            Label("SubscriptionOfferView", systemImage: "tag.fill")
        } footer: {
            InfoBox {
                InfoItem.note("Present as a .sheet for intro, promo, or win-back offers")
                InfoItem.api(".subscriptionOfferViewStyle(.automatic)", "system default layout")
                InfoItem.api(".subscriptionOfferViewStyle(.compact)", "smaller card layout")
                InfoItem.availability("iOS 18+")
            }
        }
        .sheet(isPresented: $showSheet) {
            if #available(iOS 18.0, *) {
                switch offerStyle {
                case .automatic:
                    SubscriptionOfferView(groupID: "763D6759", visibleRelationship: .all)
                case .compact:
                    SubscriptionOfferView(groupID: "763D6759", visibleRelationship: .all)
                        .subscriptionOfferViewStyle(.compact)
                }
            } else {
                ContentUnavailableView(
                    "Requires iOS 18",
                    systemImage: "exclamationmark.triangle",
                    description: Text("SubscriptionOfferView is available on iOS 18 and later.")
                )
            }
        }
    }
}

// MARK: - Shared Style Options

enum ProductViewStyleOption: String, CaseIterable, Identifiable {
    case large, regular, compact
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

enum SubscriptionControlStyleOption: String, CaseIterable, Identifiable {
    case buttons, picker, prominentPicker, compactPicker
    var id: String { rawValue }
    var label: String {
        switch self {
        case .buttons:         return ".buttons"
        case .picker:          return ".picker"
        case .prominentPicker: return ".prominentPicker"
        case .compactPicker:   return ".compactPicker"
        }
    }
}

enum SubscriptionOfferStyleOption: String, CaseIterable, Identifiable {
    case automatic, compact
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

// MARK: - Helpers

extension View {
    @ViewBuilder
    func applyBorderIfNeeded(_ apply: Bool) -> some View {
        if apply { self.productIconBorder() } else { self }
    }
}

#Preview {
    NavigationStack {
        SKViewsDemoScreen()
    }
}

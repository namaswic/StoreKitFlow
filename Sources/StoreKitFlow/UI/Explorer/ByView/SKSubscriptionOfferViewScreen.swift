import SwiftUI
import StoreKit

struct SKSubscriptionOfferViewScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore
    @State private var offerStyle: SubscriptionOfferStyleOption = .automatic
    @State private var visibleRelationship: OfferRelationshipOption = .all
    @State private var showSheet = false
    @State private var useDetailAction = false
    @State private var detailActionFired = false

    private var groupID: String { store.configuration.subscriptionGroupIDs.first ?? "763D6759" }

    @State private var selectedSection: OfferViewSection? = nil

    private enum OfferViewSection: String, CaseIterable, Identifiable {
        case detailAction        = "detailAction"
        case preview             = "Preview"
        case style               = "subscriptionOfferViewStyle"
        case visibleRelationship = "visibleRelationship"
        var id: String { rawValue }
    }

    var body: some View {
        List {
            if selectedSection == nil || selectedSection == .style               { styleSection }
            if selectedSection == nil || selectedSection == .visibleRelationship { relationshipSection }
            if selectedSection == nil || selectedSection == .detailAction        { detailActionSection }
            if selectedSection == nil || selectedSection == .preview             { previewSection }
        }
        .listSectionSpacing(12)
        .navigationTitle("SubscriptionOfferView")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: selectedSection == nil) { selectedSection = nil }
                    ForEach(OfferViewSection.allCases) { section in
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
        .sheet(isPresented: $showSheet) { offerSheet }
    }

    // MARK: - Style

    private var styleSection: some View {
        Section {
            if #available(iOS 26.0, *) {
                Picker("subscriptionOfferViewStyle", selection: $offerStyle) {
                    ForEach(SubscriptionOfferStyleOption.allCases) { Text($0.label).tag($0) }
                }
                .hint(".automatic adapts to the offer type, .compact uses a smaller card layout")
            } else {
                ContentUnavailableView(
                    "Requires iOS 26",
                    systemImage: "exclamationmark.triangle",
                    description: Text("SubscriptionOfferView requires iOS 18 or later.")
                )
                .listRowBackground(Color.clear)
            }
        } header: {
            Label("subscriptionOfferViewStyle", systemImage: "paintbrush")
        } footer: {
            InfoBox {
                InfoItem.note("Always present SubscriptionOfferView as a sheet — it handles its own dismiss.")
                InfoItem.api(".subscriptionOfferViewStyle(.automatic)", "system-default layout — adapts to the offer type (intro, promo, win-back)")
                InfoItem.api(".subscriptionOfferViewStyle(.compact)", "smaller card layout — useful in space-constrained contexts")
                InfoItem.availability("iOS 26+")
            }
        }
    }

    // MARK: - visibleRelationship

    private var relationshipSection: some View {
        Section {
            if #available(iOS 26.0, *) {
                Picker("visibleRelationship", selection: $visibleRelationship) {
                    ForEach(OfferRelationshipOption.allCases) { Text($0.label).tag($0) }
                }
                .hint(".all shows offers for all relationships, .current shows only the user's active subscription offers")
            }
        } header: {
            Label("visibleRelationship", systemImage: "person.2.fill")
        } footer: {
            InfoBox {
                InfoItem.api("visibleRelationship: .all", "shows offers for all relationships — new subscriptions, upgrades, downgrades, cross-grades")
                InfoItem.api("visibleRelationship: .current", "shows only offers applicable to the user's current active subscription")
            }
        }
    }

    // MARK: - Detail Action

    private var detailActionSection: some View {
        Section {
            if #available(iOS 26.0, *) {
                Toggle("Use subscriptionOfferViewDetailAction", isOn: $useDetailAction)
                    .hint("Registers a closure called when the user taps the detail/info button within the offer view")
                if detailActionFired {
                    Label("Detail action triggered", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            } else {
                ContentUnavailableView(
                    "Requires iOS 26",
                    systemImage: "exclamationmark.triangle",
                    description: Text("subscriptionOfferViewDetailAction requires iOS 26 or later.")
                )
                .listRowBackground(Color.clear)
            }
        } header: {
            Label("subscriptionOfferViewDetailAction", systemImage: "info.circle.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".subscriptionOfferViewDetailAction { … }", "iOS 26+ — closure called when the user taps the detail button in SubscriptionOfferView — present a custom detail/info screen")
                InfoItem.note("Pass nil to remove a detail action set by an ancestor view.")
                InfoItem.availability("iOS 26+, iPhone only")
            }
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        Section {
            if #available(iOS 26.0, *) {
                Button { showSheet = true } label: {
                    Label("Open SubscriptionOfferView", systemImage: "tag.fill")
                }
            }
        }
    }

    // MARK: - Sheet

    private var offerSheetModifiers: [String] {
        if #available(iOS 26.0, *) {
            var lines = ["SubscriptionOfferView(groupID: groupID, visibleRelationship: .\(visibleRelationship.rawValue))"]
            if offerStyle == .compact { lines.append("  .subscriptionOfferViewStyle(.compact)") }
            if useDetailAction { lines.append("  .subscriptionOfferViewDetailAction { /* handle detail tap */ }") }
            return lines
        } else {
            return ["// SubscriptionOfferView requires iOS 26+"]
        }
    }

    @ViewBuilder
    private var offerSheet: some View {
        if #available(iOS 26.0, *) {
            PreviewSheet(
                title: "SubscriptionOfferView",
                modifiers: offerSheetModifiers,
                variants: [
                    PreviewSheetVariant(
                        label: ".automatic",
                        modifiers: [
                            "SubscriptionOfferView(groupID: groupID, visibleRelationship: .\(visibleRelationship.rawValue))",
                        ] + (useDetailAction ? ["  .subscriptionOfferViewDetailAction { ... }"] : []),
                        content: AnyView(
                            applyDetailActionIfNeeded(
                                SubscriptionOfferView(groupID: groupID, visibleRelationship: visibleRelationship == .all ? .all : .current)
                            )
                        )
                    ),
                    PreviewSheetVariant(
                        label: ".compact",
                        modifiers: [
                            "SubscriptionOfferView(groupID: groupID, visibleRelationship: .\(visibleRelationship.rawValue))",
                            "  .subscriptionOfferViewStyle(.compact)",
                        ] + (useDetailAction ? ["  .subscriptionOfferViewDetailAction { ... }"] : []),
                        content: AnyView(
                            applyDetailActionIfNeeded(
                                SubscriptionOfferView(groupID: groupID, visibleRelationship: visibleRelationship == .all ? .all : .current)
                                    .subscriptionOfferViewStyle(.compact)
                            )
                        )
                    ),
                ]
            ) { EmptyView() }
        } else {
            EmptyView()
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func applyDetailActionIfNeeded<V: View>(_ view: V) -> some View {
        if useDetailAction {
            view.subscriptionOfferViewDetailAction { detailActionFired = true }
        } else {
            view
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private var baseOfferView: some View {
        switch (offerStyle, visibleRelationship) {
        case (.automatic, .all):
            SubscriptionOfferView(groupID: groupID, visibleRelationship: .all)
        case (.automatic, .current):
            SubscriptionOfferView(groupID: groupID, visibleRelationship: .current)
        case (.compact, .all):
            SubscriptionOfferView(groupID: groupID, visibleRelationship: .all)
                .subscriptionOfferViewStyle(.compact)
        case (.compact, .current):
            SubscriptionOfferView(groupID: groupID, visibleRelationship: .current)
                .subscriptionOfferViewStyle(.compact)
        }
    }
}

private enum OfferRelationshipOption: String, CaseIterable, Identifiable {
    case all, current
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

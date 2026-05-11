import SwiftUI
import StoreKit

struct SKSubscriptionOfferViewScreen: View {
    @State private var offerStyle: SubscriptionOfferStyleOption = .automatic
    @State private var visibleRelationship: OfferRelationshipOption = .all
    @State private var showSheet = false

    private let groupID = "763D6759"

    var body: some View {
        List {
            styleSection
            relationshipSection
            previewSection
        }
        .listSectionSpacing(12)
        .navigationTitle("SubscriptionOfferView")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSheet) { offerSheet }
    }

    // MARK: - Style

    private var styleSection: some View {
        Section {
            if #available(iOS 18.0, *) {
                Picker("subscriptionOfferViewStyle", selection: $offerStyle) {
                    ForEach(SubscriptionOfferStyleOption.allCases) { Text($0.label).tag($0) }
                }
            } else {
                ContentUnavailableView(
                    "Requires iOS 18",
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
                InfoItem.availability("iOS 18+")
            }
        }
    }

    // MARK: - visibleRelationship

    private var relationshipSection: some View {
        Section {
            if #available(iOS 18.0, *) {
                Picker("visibleRelationship", selection: $visibleRelationship) {
                    ForEach(OfferRelationshipOption.allCases) { Text($0.label).tag($0) }
                }
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

    // MARK: - Preview

    private var previewSection: some View {
        Section {
            if #available(iOS 18.0, *) {
                Button { showSheet = true } label: {
                    Label("Open SubscriptionOfferView", systemImage: "tag.fill")
                }
            }
        }
    }

    // MARK: - Sheet

    @ViewBuilder
    private var offerSheet: some View {
        if #available(iOS 18.0, *) {
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
}

// MARK: - Enums

private enum OfferRelationshipOption: String, CaseIterable, Identifiable {
    case all, current
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

#Preview {
    NavigationStack {
        SKSubscriptionOfferViewScreen()
    }
}

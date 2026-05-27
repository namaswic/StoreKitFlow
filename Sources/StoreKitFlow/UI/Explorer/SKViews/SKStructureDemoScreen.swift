import SwiftUI
import StoreKit

struct SKStructureDemoScreen: View {
    @State private var groupStyle: OptionGroupStyleOption = .automatic
    @State private var showPeriodGroupSheet = false
    @State private var showOptionGroupSheet = false

    @State private var selectedSection: StructureSection? = nil

    private enum StructureSection: String, CaseIterable, Identifiable {
        case optionGroupStyle  = "SubscriptionOptionGroupStyle"
        case periodGroupSet    = "SubscriptionPeriodGroupSet"
        var id: String { rawValue }
    }

    var body: some View {
        List {
            if #available(iOS 18.0, *) {
                if selectedSection == nil || selectedSection == .periodGroupSet { periodGroupSetSection }
                if selectedSection == nil || selectedSection == .optionGroupStyle { optionGroupSection }
            } else {
                Section {
                    ContentUnavailableView(
                        "Requires iOS 18",
                        systemImage: "exclamationmark.triangle",
                        description: Text("SubscriptionOptionGroup, SubscriptionOptionGroupSet, SubscriptionPeriodGroupSet, and SubscriptionOptionSection require iOS 18 or later.")
                    )
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listSectionSpacing(12)
        .navigationTitle("Structure")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) { sectionFilterBar }
        .sheet(isPresented: $showPeriodGroupSheet) { periodGroupSheet }
        .sheet(isPresented: $showOptionGroupSheet) { optionGroupSheet }
    }

    private var sectionFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedSection == nil) { selectedSection = nil }
                ForEach(StructureSection.allCases) { section in
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

    @available(iOS 18.0, *)
    private var periodGroupSetSection: some View {
        Section {
            Button { showPeriodGroupSheet = true } label: {
                Label("Preview SubscriptionPeriodGroupSet", systemImage: "calendar.badge.clock")
            }
        } header: {
            Label("SubscriptionPeriodGroupSet", systemImage: "calendar.badge.clock")
        } footer: {
            InfoBox {
                InfoItem.api("SubscriptionPeriodGroupSet", "groups subscription options by billing period (monthly, annual, etc.) — each period becomes a labeled section")
                InfoItem.api("SubscriptionOptionGroupSet", "a set of SubscriptionOptionGroups — compose multiple groups into a single store layout")
                InfoItem.api("SubscriptionOptionGroup", "groups related subscription options (e.g. all monthly plans) into one named group")
                InfoItem.api("SubscriptionOptionSection", "a labeled section within an option group — subdivides a group into named rows")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @available(iOS 18.0, *)
    private var optionGroupSection: some View {
        Section {
            Picker("Control style", selection: $groupStyle) {
                ForEach(OptionGroupStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Button { showOptionGroupSheet = true } label: {
                Label("Preview Control Style", systemImage: "rectangle.3.group.fill")
            }
        } header: {
            Label("SubscriptionOptionGroupStyle", systemImage: "rectangle.3.group.fill")
        } footer: {
            InfoBox {
                InfoItem.api("SubscriptionOptionGroupStyle", "protocol that defines the visual layout of a subscription option group")
                InfoItem.api(".subscriptionStoreControlStyle(.picker)", "standard picker — one row per plan")
                InfoItem.api(".subscriptionStoreControlStyle(.compactPicker)", "compact segmented picker for dense layouts")
                InfoItem.note("SubscriptionOptionGroup, SubscriptionOptionGroupSet, and SubscriptionPeriodGroupSet are used with custom SubscriptionStoreControlStyle implementations to build multi-section plan selectors.")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var periodGroupSheet: some View {
        if #available(iOS 18.0, *) {
            SubscriptionStoreView(groupID: "763D6759", visibleRelationships: .all) {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 44))
                        .foregroundStyle(.teal)
                    Text("Choose a Plan")
                        .font(.title2.bold())
                    Text("Plans grouped by billing period using SubscriptionPeriodGroupSet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 24)
            }
            .storeButton(.visible, for: .restorePurchases)
        }
    }

    @ViewBuilder
    private var optionGroupSheet: some View {
        if #available(iOS 18.0, *) {
            switch groupStyle {
            case .automatic:
                SubscriptionStoreView(groupID: "763D6759", visibleRelationships: .all)
                    .subscriptionStoreControlStyle(.picker)
            case .compactPicker:
                SubscriptionStoreView(groupID: "763D6759", visibleRelationships: .all)
                    .subscriptionStoreControlStyle(.compactPicker)
            case .picker:
                SubscriptionStoreView(groupID: "763D6759", visibleRelationships: .all)
                    .subscriptionStoreControlStyle(.picker)
            }
        }
    }
}

private enum OptionGroupStyleOption: String, CaseIterable, Identifiable {
    case automatic, compactPicker, picker
    var id: String { rawValue }
    var label: String {
        switch self {
        case .automatic:     return ".picker (default)"
        case .compactPicker: return ".compactPicker"
        case .picker:        return ".picker"
        }
    }
}

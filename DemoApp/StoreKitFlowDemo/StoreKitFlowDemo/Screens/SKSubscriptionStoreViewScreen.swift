import SwiftUI
import StoreKitFlow
import StoreKit

struct SKSubscriptionStoreViewScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore
    private var groupID: String { store.configuration.subscriptionGroupIDs.first ?? "763D6759" }

    // Appearance
    @State private var controlStyle: SubscriptionControlStyleOption = .prominentPicker
    @State private var controlBackground: ControlBackgroundOption = .automatic
    @State private var buttonLabel: ButtonLabelOption = .action
    @State private var showMarketingHeader = true
    @State private var showAppearanceSheet = false

    // Container Background (iOS 18+)
    @State private var containerPlacement: ContainerPlacementOption = .subscriptionStore
    @State private var containerColor: ContainerColorOption = .purple
    @State private var showContainerSheet = false

    // UI Customization (iOS 18+)
    @State private var pickerItemBg: PickerItemBgOption = .regularMaterial
    @State private var useCustomIcon = false
    @State private var showUICustomSheet = false

    // Custom Controls (iOS 18+)
    @State private var accentColor: AccentColorOption = .purple
    @State private var showFamilyBadge = true
    @State private var customButtonLabel: ButtonLabelOption = .multiline
    @State private var showCustomControlSheet = false

    // Accessory (iOS 18+)
    @State private var showRestorePurchases = true
    @State private var showSignIn = false
    @State private var showRedeemCode = false
    @State private var showPolicies = true
    @State private var useSignInAction = false
    @State private var showAccessorySheet = false

    // Data Binding
    @State private var subscriptionStatuses: [Product.SubscriptionInfo.Status] = []

    // Store Events
    @State private var purchaseStartLog: String?
    @State private var purchaseCompletionLog: String?

    // Sheets & Overlays
    @State private var showManageSheet = false
    @State private var showOfferCodeSheet = false
    @State private var refundTransactionID: UInt64?
    @State private var showRefundSheet = false
    @State private var refundResult: String?

    // Structure (iOS 18+)
    @State private var structureControlStyle: SubscriptionControlStyleOption = .picker
    @State private var structureShowHeader = true
    @State private var showStructureSheet = false

    var body: some View {
        List {
            appearanceSection
            if #available(iOS 18.0, *) {
                containerBackgroundSection
                uiCustomizationSection
                customControlsSection
                accessorySection
            } else {
                Section {
                    ContentUnavailableView(
                        "More options on iOS 18",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Container Background, UI Customization, Custom Controls, and Accessory require iOS 18.")
                    )
                    .listRowBackground(Color.clear)
                }
            }
            storeEventsSection
            sheetsAndOverlaysSection
            dataBindingSection
            if #available(iOS 18.0, *) {
                structureSection
            }
        }
        .listSectionSpacing(12)
        .navigationTitle("SubscriptionStoreView")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAppearanceSheet) { appearanceSheet }
        .sheet(isPresented: $showContainerSheet) { containerSheet }
        .sheet(isPresented: $showUICustomSheet) { uiCustomSheet }
        .sheet(isPresented: $showCustomControlSheet) { customControlSheet }
        .sheet(isPresented: $showAccessorySheet) { accessorySheet }
        .sheet(isPresented: $showStructureSheet) { structureSheet }
        .manageSubscriptionsSheet(isPresented: $showManageSheet)
        .offerCodeRedemption(isPresented: $showOfferCodeSheet)
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
                    if case .success(let verificationResult) = purchaseResult {
                        refundTransactionID = (try? verificationResult.payloadValue)?.id
                    }
                case .failure(let error):
                    purchaseCompletionLog = "✗ \(error.localizedDescription)"
                }
            }
        }
        .subscriptionStatusTask(for: groupID) { taskState in
            if case .success(let statuses) = taskState {
                subscriptionStatuses = statuses
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            Picker("subscriptionStoreControlStyle", selection: $controlStyle) {
                ForEach(SubscriptionControlStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Picker("subscriptionStoreControlBackground", selection: $controlBackground) {
                ForEach(ControlBackgroundOption.allCases) { Text($0.label).tag($0) }
            }
            Picker("subscriptionStoreButtonLabel", selection: $buttonLabel) {
                ForEach(ButtonLabelOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Custom marketingContent: header", isOn: $showMarketingHeader)
            Button { showAppearanceSheet = true } label: {
                Label("Preview Appearance", systemImage: "paintbrush.fill")
            }
        } header: {
            Label("Appearance", systemImage: "paintbrush.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".subscriptionStoreControlStyle(.prominentPicker)", "large card-style picker — highlighted selection")
                InfoItem.api(".subscriptionStoreControlStyle(.picker)", "standard compact picker")
                InfoItem.api(".subscriptionStoreControlStyle(.compactPicker)", "segmented-style compact picker")
                InfoItem.api(".subscriptionStoreControlStyle(.buttons)", "one button per plan — no picker")
                InfoItem.api(".subscriptionStoreControlBackground(.automatic)", "adapts panel background to light/dark mode")
                InfoItem.api(".subscriptionStoreControlBackground(.clear)", "removes panel background entirely")
                InfoItem.api(".subscriptionStoreButtonLabel(.action)", "shows 'Subscribe' on the button")
                InfoItem.api(".subscriptionStoreButtonLabel(.displayName)", "shows plan name (e.g. 'Monthly')")
                InfoItem.api(".subscriptionStoreButtonLabel(.price)", "shows price (e.g. '$4.99')")
                InfoItem.api(".subscriptionStoreButtonLabel(.multiline)", "stacks plan name and price")
                InfoItem.api("marketingContent:", "custom header view shown above the plan list")
            }
        }
    }

    @ViewBuilder
    private var appearanceSheet: some View {
        let header = { AnyView(showMarketingHeader ? AnyView(paywallHeader) : AnyView(EmptyView())) }
        switch controlStyle {
        case .buttons:
            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                .subscriptionStoreControlStyle(.buttons)
                .applyControlBackground(controlBackground)
                .applyButtonLabel(buttonLabel)
        case .picker:
            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                .subscriptionStoreControlStyle(.picker)
                .applyControlBackground(controlBackground)
                .applyButtonLabel(buttonLabel)
        case .prominentPicker:
            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                .subscriptionStoreControlStyle(.prominentPicker)
                .applyControlBackground(controlBackground)
                .applyButtonLabel(buttonLabel)
        case .compactPicker:
            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                .subscriptionStoreControlStyle(.compactPicker)
                .applyControlBackground(controlBackground)
                .applyButtonLabel(buttonLabel)
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

    // MARK: - Container Background (iOS 18+)

    @available(iOS 18.0, *)
    private var containerBackgroundSection: some View {
        Section {
            Picker("Placement", selection: $containerPlacement) {
                ForEach(ContainerPlacementOption.allCases) { Text($0.label).tag($0) }
            }
            Picker("Color", selection: $containerColor) {
                ForEach(ContainerColorOption.allCases) { Text($0.label).tag($0) }
            }
            Button { showContainerSheet = true } label: {
                Label("Preview Container Background", systemImage: "rectangle.fill.on.rectangle.fill")
            }
        } header: {
            Label("containerBackground", systemImage: "rectangle.fill.on.rectangle.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".containerBackground(_:for: .subscriptionStore)", "fills the entire SubscriptionStoreView background")
                InfoItem.api(".containerBackground(_:for: .subscriptionStoreHeader)", "fills only the marketing header area")
                InfoItem.api(".containerBackground(_:for: .subscriptionStoreFullHeight)", "extends background to full screen height including safe area")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var containerSheet: some View {
        if #available(iOS 18.0, *) {
            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all) {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(containerColor.color)
                    Text("Go Pro")
                        .font(.title2.bold())
                }
                .padding(.top, 24)
            }
            .applyContainerBackground(color: containerColor.color, placement: containerPlacement)
        }
    }

    // MARK: - UI Customization (iOS 18+)

    @available(iOS 18.0, *)
    private var uiCustomizationSection: some View {
        Section {
            Picker("subscriptionStorePickerItemBackground", selection: $pickerItemBg) {
                ForEach(PickerItemBgOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Custom subscriptionStoreControlIcon", isOn: $useCustomIcon)
            Button { showUICustomSheet = true } label: {
                Label("Preview UI Customization", systemImage: "slider.vertical.3")
            }
        } header: {
            Label("UI Customization", systemImage: "slider.vertical.3")
        } footer: {
            InfoBox {
                InfoItem.api(".subscriptionStorePickerItemBackground(.regularMaterial)", "frosted-glass material behind each picker row")
                InfoItem.api(".subscriptionStorePickerItemBackground(.thinMaterial)", "thinner frosted-glass effect")
                InfoItem.api(".subscriptionStorePickerItemBackground(Color.clear)", "transparent — no row background")
                InfoItem.api(".subscriptionStoreControlIcon(_:)", "replaces the default icon in the control area with a custom view")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var uiCustomSheet: some View {
        if #available(iOS 18.0, *) {
            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)
                .subscriptionStoreControlStyle(.picker)
                .applyPickerItemBackground(pickerItemBg)
                .applyCustomIconIfNeeded(useCustomIcon)
        }
    }

    // MARK: - Custom Controls (iOS 18+)

    @available(iOS 18.0, *)
    private var customControlsSection: some View {
        Section {
            Picker("Accent color", selection: $accentColor) {
                ForEach(AccentColorOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Show family sharing badge", isOn: $showFamilyBadge)
            Picker("Button label", selection: $customButtonLabel) {
                ForEach(ButtonLabelOption.allCases) { Text($0.label).tag($0) }
            }
            Button { showCustomControlSheet = true } label: {
                Label("Preview Custom Controls", systemImage: "slider.horizontal.3")
            }
        } header: {
            Label("Custom Controls", systemImage: "slider.horizontal.3")
        } footer: {
            InfoBox {
                InfoItem.api("SubscriptionStorePicker", "lays out each plan option using your own row view")
                InfoItem.api("SubscriptionStorePickerOption", "provides displayName, price, isSelected, isFamilyShareable per plan")
                InfoItem.api("SubscriptionStoreButton", "renders the confirm/subscribe action button")
                InfoItem.api(".subscriptionStoreControlStyle(customStyle)", "applies your custom SubscriptionStoreControlStyle to SubscriptionStoreView")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var customControlSheet: some View {
        if #available(iOS 18.0, *) {
            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all) {
                VStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 44))
                        .foregroundStyle(accentColor.color)
                    Text("Choose Your Plan")
                        .font(.title2.bold())
                }
                .padding(.top, 24)
            }
            .subscriptionStoreControlStyle(
                SSVCustomPickerStyle(
                    accentColor: accentColor.color,
                    showFamilyBadge: showFamilyBadge,
                    buttonLabelStyle: customButtonLabel
                )
            )
        }
    }

    // MARK: - Accessory (iOS 18+)

    @available(iOS 18.0, *)
    private var accessorySection: some View {
        Section {
            Toggle("Restore Purchases", isOn: $showRestorePurchases)
            Toggle("Sign In", isOn: $showSignIn)
            Toggle("Redeem Code", isOn: $showRedeemCode)
            Toggle("Policies", isOn: $showPolicies)
            Toggle("Custom subscriptionStoreSignInAction", isOn: $useSignInAction)
            Button { showAccessorySheet = true } label: {
                Label("Preview — tap to see changes", systemImage: "ellipsis.circle.fill")
            }
        } header: {
            Label("Accessory & Utility", systemImage: "ellipsis.circle.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".storeButton(.visible, for: .restorePurchases)", "shows the 'Restore Purchases' button")
                InfoItem.api(".storeButton(.visible, for: .signIn)", "shows a sign-in button for unauthenticated users")
                InfoItem.api(".storeButton(.visible, for: .redeemCode)", "shows a 'Redeem Code' entry point")
                InfoItem.api(".storeButton(.visible, for: .policies)", "shows privacy policy and terms of service links")
                InfoItem.api(".subscriptionStoreSignInAction {}", "closure called when the sign-in button is tapped — present your own auth flow")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var accessorySheet: some View {
        if #available(iOS 18.0, *) {
            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)
                .storeButton(showRestorePurchases ? .visible : .hidden, for: .restorePurchases)
                .storeButton(showSignIn ? .visible : .hidden, for: .signIn)
                .storeButton(showRedeemCode ? .visible : .hidden, for: .redeemCode)
                .storeButton(showPolicies ? .visible : .hidden, for: .policies)
                .applySignInActionIfNeeded(useSignInAction)
        }
    }

    // MARK: - Store Events

    private var storeEventsSection: some View {
        Section {
            if let log = purchaseStartLog {
                LabeledContent("onInAppPurchaseStart", value: log)
            } else {
                Text("Tap Subscribe in any sheet above to trigger onInAppPurchaseStart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let log = purchaseCompletionLog {
                LabeledContent("onInAppPurchaseCompletion", value: log)
                    .lineLimit(3)
            } else {
                Text("Complete or cancel a purchase to trigger onInAppPurchaseCompletion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("Store Events", systemImage: "bell.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".onInAppPurchaseStart { product in … }", "async closure called the moment the user initiates a purchase — before the payment sheet appears")
                InfoItem.api(".onInAppPurchaseCompletion { product, result in … }", "async closure called after the purchase sheet is dismissed — result is Result<Product.PurchaseResult, Error>")
                InfoItem.note("Both modifiers bubble up the view hierarchy — attach them on any ancestor of SubscriptionStoreView.")
            }
        }
    }

    // MARK: - Sheets & Overlays

    private var sheetsAndOverlaysSection: some View {
        Section {
            Button { showManageSheet = true } label: {
                Label("Manage Subscriptions", systemImage: "person.crop.circle.badge.checkmark")
            }
            Button { showOfferCodeSheet = true } label: {
                Label("Redeem Offer Code", systemImage: "ticket.fill")
            }
            if let id = refundTransactionID {
                LabeledContent("Transaction ID", value: "\(id)")
            }
            Button("Show Refund Sheet") { showRefundSheet = true }
            if let result = refundResult {
                LabeledContent("Refund Result", value: result)
            }
        } header: {
            Label("Sheets & Overlays", systemImage: "rectangle.stack.badge.plus")
        } footer: {
            InfoBox {
                InfoItem.api(".manageSubscriptionsSheet(isPresented:)", "presents Apple's system subscription management UI — users can cancel, upgrade, or downgrade without leaving your app")
                InfoItem.api(".offerCodeRedemption(isPresented:)", "presents Apple's system UI for entering a promo or offer code — redeems it automatically on confirmation")
                InfoItem.api(".refundRequestSheet(for: transactionID, isPresented:)", "presents Apple's refund request UI for a specific transaction — onDismiss receives Result<RefundRequestStatus, RefundRequestError>")
                InfoItem.note("refundRequestSheet requires a real Transaction.ID — auto-captured here from onInAppPurchaseCompletion after a purchase.")
            }
        }
    }

    // MARK: - Data Binding

    private var dataBindingSection: some View {
        Section {
            if subscriptionStatuses.isEmpty {
                Text("No active subscriptions in this group.")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(subscriptionStatuses.indices, id: \.self) { i in
                    let status = subscriptionStatuses[i]
                    LabeledContent("Status \(i + 1)", value: status.state.localizedDescription)
                }
            }
        } header: {
            Label("subscriptionStatusTask", systemImage: "bolt.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".subscriptionStatusTask(groupID:)", "declarative modifier — fires on appear and whenever subscription status changes in the group")
                InfoItem.api("taskState: [Product.SubscriptionInfo.Status]?", "array of active statuses for all subscriptions in the group — nil while loading")
                InfoItem.note("Handles renewals, expirations, and cancellations automatically — no manual polling needed.")
                InfoItem.availability("iOS 17+")
            }
        }
    }

    // MARK: - Structure (iOS 18+)

    @available(iOS 18.0, *)
    private var structureSection: some View {
        Section {
            Picker("subscriptionStoreControlStyle", selection: $structureControlStyle) {
                ForEach(SubscriptionControlStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Custom marketing header", isOn: $structureShowHeader)
            Button { showStructureSheet = true } label: {
                Label("Preview Structure Layout", systemImage: "calendar.badge.clock")
            }
        } header: {
            Label("Structure", systemImage: "rectangle.3.group.fill")
        } footer: {
            InfoBox {
                InfoItem.api("SubscriptionPeriodGroupSet", "groups subscription options by billing period — each period (monthly, annual) becomes a labeled section")
                InfoItem.api("SubscriptionOptionGroupSet", "a set of SubscriptionOptionGroups — compose multiple named groups into one store layout")
                InfoItem.api("SubscriptionOptionGroup", "groups related options (e.g. all monthly plans) under a single named heading")
                InfoItem.api("SubscriptionOptionSection", "a labeled sub-section within an option group")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var structureSheet: some View {
        if #available(iOS 18.0, *) {
            let header = { AnyView(structureShowHeader ? AnyView(structureHeader) : AnyView(EmptyView())) }
            switch structureControlStyle {
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
    }

    private var structureHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 44))
                .foregroundStyle(.teal)
            Text("Choose a Plan")
                .font(.title2.bold())
            Text("Options grouped by billing period using SubscriptionPeriodGroupSet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 24)
    }
}

// MARK: - Custom Control Style (iOS 18+)

@available(iOS 18.0, *)
private struct SSVCustomPickerStyle: SubscriptionStoreControlStyle {
    let accentColor: Color
    let showFamilyBadge: Bool
    let buttonLabelStyle: ButtonLabelOption

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 12) {
            SubscriptionStorePicker(configuration) { option in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(option.displayName).font(.headline)
                            if showFamilyBadge && option.isFamilyShareable {
                                Label("Family", systemImage: "figure.2.and.child.holdinghands")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(accentColor.opacity(0.15), in: Capsule())
                                    .foregroundStyle(accentColor)
                            }
                        }
                        Text(option.price.formatted())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: option.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(option.isSelected ? accentColor : .secondary)
                        .font(.title2)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(option.isSelected ? accentColor.opacity(0.1) : Color(.secondarySystemFill))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(option.isSelected ? accentColor : .clear, lineWidth: 2)
                        )
                )
            } confirmation: { option in
                switch buttonLabelStyle {
                case .action:      SubscriptionStoreButton(option).subscriptionStoreButtonLabel(.action).tint(accentColor)
                case .displayName: SubscriptionStoreButton(option).subscriptionStoreButtonLabel(.displayName).tint(accentColor)
                case .price:       SubscriptionStoreButton(option).subscriptionStoreButtonLabel(.price).tint(accentColor)
                case .multiline:   SubscriptionStoreButton(option).subscriptionStoreButtonLabel(.multiline).tint(accentColor)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Local Enums

private enum ControlBackgroundOption: String, CaseIterable, Identifiable {
    case automatic, clear
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

private enum ContainerPlacementOption: String, CaseIterable, Identifiable {
    case subscriptionStore, subscriptionStoreHeader, subscriptionStoreFullHeight
    var id: String { rawValue }
    var label: String {
        switch self {
        case .subscriptionStore:           return ".subscriptionStore"
        case .subscriptionStoreHeader:     return ".subscriptionStoreHeader"
        case .subscriptionStoreFullHeight: return ".subscriptionStoreFullHeight"
        }
    }
}

private enum ContainerColorOption: String, CaseIterable, Identifiable {
    case purple, blue, green, orange
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .purple: return .purple
        case .blue:   return .blue
        case .green:  return .green
        case .orange: return .orange
        }
    }
}

private enum PickerItemBgOption: String, CaseIterable, Identifiable {
    case regularMaterial, thinMaterial, clear
    var id: String { rawValue }
    var label: String {
        switch self {
        case .regularMaterial: return ".regularMaterial"
        case .thinMaterial:    return ".thinMaterial"
        case .clear:           return ".clear"
        }
    }
}

private enum AccentColorOption: String, CaseIterable, Identifiable {
    case purple, blue, green, orange
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .purple: return .purple
        case .blue:   return .blue
        case .green:  return .green
        case .orange: return .orange
        }
    }
}

// MARK: - View Extensions

private extension View {
    @ViewBuilder
    func applyControlBackground(_ option: ControlBackgroundOption) -> some View {
        switch option {
        case .automatic: self.subscriptionStoreControlBackground(.automatic)
        case .clear:     self.subscriptionStoreControlBackground(.clear)
        }
    }

    @ViewBuilder
    func applyButtonLabel(_ option: ButtonLabelOption) -> some View {
        switch option {
        case .action:      self.subscriptionStoreButtonLabel(.action)
        case .displayName: self.subscriptionStoreButtonLabel(.displayName)
        case .price:       self.subscriptionStoreButtonLabel(.price)
        case .multiline:   self.subscriptionStoreButtonLabel(.multiline)
        }
    }

    @available(iOS 18.0, *)
    @ViewBuilder
    func applyPickerItemBackground(_ option: PickerItemBgOption) -> some View {
        switch option {
        case .regularMaterial: self.subscriptionStorePickerItemBackground(.regularMaterial)
        case .thinMaterial:    self.subscriptionStorePickerItemBackground(.thinMaterial)
        case .clear:           self.subscriptionStorePickerItemBackground(Color.clear)
        }
    }

    @available(iOS 18.0, *)
    @ViewBuilder
    func applyCustomIconIfNeeded(_ custom: Bool) -> some View {
        if custom {
            self.subscriptionStoreControlIcon { _, _  in
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
            }
        } else {
            self
        }
    }

    @available(iOS 18.0, *)
    @ViewBuilder
    func applyContainerBackground(color: Color, placement: ContainerPlacementOption) -> some View {
        switch placement {
        case .subscriptionStore:
            self.containerBackground(color.gradient, for: .subscriptionStore)
        case .subscriptionStoreHeader:
            self.containerBackground(color.gradient, for: .subscriptionStoreHeader)
        case .subscriptionStoreFullHeight:
            self.containerBackground(color.gradient, for: .subscriptionStoreFullHeight)
        }
    }

    @available(iOS 18.0, *)
    @ViewBuilder
    func applySignInActionIfNeeded(_ enabled: Bool) -> some View {
        if enabled {
            self.subscriptionStoreSignInAction { }
        } else {
            self
        }
    }
}

#Preview {
    NavigationStack {
        SKSubscriptionStoreViewScreen()
    }
}

import SwiftUI
import StoreKit

struct SKSubscriptionStoreViewScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore
    private var groupID: String { store.configuration.subscriptionGroupIDs.first ?? "763D6759" }

    @State private var controlStyle: SubscriptionControlStyleOption = .prominentPicker
    @State private var controlBackground: ControlBackgroundOption = .automatic
    @State private var buttonLabel: ButtonLabelOption = .action
    @State private var showMarketingHeader = true
    @State private var showAppearanceSheet = false

    @State private var containerPlacement: ContainerPlacementOption = .subscriptionStore
    @State private var containerColor: ContainerColorOption = .purple
    @State private var showContainerSheet = false

    @State private var pickerItemBg: PickerItemBgOption = .regularMaterial
    @State private var useCustomIcon = false
    @State private var showUICustomSheet = false

    @State private var accentColor: AccentColorOption = .purple
    @State private var showFamilyBadge = true
    @State private var customButtonLabel: ButtonLabelOption = .multiline
    @State private var showCustomControlSheet = false

    @State private var showRestorePurchases = true
    @State private var showSignIn = false
    @State private var showRedeemCode = false
    @State private var showPolicies = true
    @State private var useSignInAction = false
    @State private var showAccessorySheet = false

    @State private var subscriptionStatuses: [Product.SubscriptionInfo.Status] = []

    @State private var purchaseStartLog: String?
    @State private var purchaseCompletionLog: String?

    @State private var showManageSheet = false
    @State private var showOfferCodeSheet = false
    @State private var refundTransactionID: UInt64?
    @State private var showRefundSheet = false
    @State private var refundResult: String?

    @State private var structureControlStyle: SubscriptionControlStyleOption = .picker
    @State private var structureShowHeader = true
    @State private var showStructureSheet = false

    @State private var initSource: InitSourceOption = .groupID
    @State private var useMarketingContent = true
    @State private var useStoreContent = false
    @State private var loadedProducts: [Product] = []
    @State private var showInitSheet = false

    @State private var controlPlacement: ControlPlacementOption = .automatic

    @State private var visibleRelationship: SubscriptionRelationshipOption = .all
    @State private var applyIntroOffer = false
    @State private var applyPreferredOffer = false
    @State private var showOffersSheet = false

    @State private var optionGroupStyle: OptionGroupStyleOption = .automatic

    @State private var showPrivacyPolicy = true
    @State private var showTermsOfService = true
    @State private var policyColor: PolicyColorOption = .secondary
    @State private var showPolicySheet = false

    @State private var selectedSection: SSVSection? = nil

    private enum SSVSection: String, CaseIterable, Identifiable {
        case accessory              = "Accessory"
        case appearance             = "Appearance"
        case containerBackground    = "containerBackground"
        case customControls         = "Custom Controls"
        case dataBinding            = "Data Binding"
        case initializers           = "Initializers"
        case policy                 = "Policy"
        case sheetsAndOverlays      = "Sheets & Overlays"
        case storeEvents            = "Store Events"
        case structure              = "Structure"
        case subscriptionOffers     = "Subscription Offers"
        case uiCustomization        = "UI Customization"
        var id: String { rawValue }
    }

    private enum ControlPlacementOption: String, CaseIterable, Identifiable {
        case automatic, bottomBar
        var id: String { rawValue }
        var label: String { ".\(rawValue)" }
    }

    fileprivate enum OptionGroupStyleOption: String, CaseIterable, Identifiable {
        case automatic, tabs, links
        var id: String { rawValue }
        var label: String { ".\(rawValue)" }
    }

    private enum PolicyColorOption: String, CaseIterable, Identifiable {
        case secondary, blue, red
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var color: Color {
            switch self {
            case .secondary: return .secondary
            case .blue:      return .blue
            case .red:       return .red
            }
        }
    }

    private enum SubscriptionRelationshipOption: String, CaseIterable, Identifiable {
        case all, current, upgrade, downgrade, crossgrade
        var id: String { rawValue }
        var label: String { ".\(rawValue)" }
        var value: Product.SubscriptionRelationship {
            switch self {
            case .all:        return .all
            case .current:    return .current
            case .upgrade:    return .upgrade
            case .downgrade:  return .downgrade
            case .crossgrade: return .crossgrade
            }
        }
    }

    private enum InitSourceOption: String, CaseIterable, Identifiable {
        case groupID, productIDs, subscriptions
        var id: String { rawValue }
        var label: String { ".\(rawValue)" }
    }

    var body: some View {
        List {
            if selectedSection == nil || selectedSection == .appearance          { appearanceSection }
            if #available(iOS 18.0, *) {
                if selectedSection == nil || selectedSection == .containerBackground { containerBackgroundSection }
                if selectedSection == nil || selectedSection == .uiCustomization     { uiCustomizationSection }
                if selectedSection == nil || selectedSection == .customControls      { customControlsSection }
                if selectedSection == nil || selectedSection == .accessory           { accessorySection }
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
            if selectedSection == nil || selectedSection == .initializers         { initializerSection }
            if selectedSection == nil || selectedSection == .policy              { policySection }
            if selectedSection == nil || selectedSection == .subscriptionOffers  { subscriptionOffersSection }
            if selectedSection == nil || selectedSection == .storeEvents         { storeEventsSection }
            if selectedSection == nil || selectedSection == .sheetsAndOverlays   { sheetsAndOverlaysSection }
            if selectedSection == nil || selectedSection == .dataBinding         { dataBindingSection }
            if #available(iOS 18.0, *) {
                if selectedSection == nil || selectedSection == .structure        { structureSection }
            }
        }
        .listSectionSpacingCompact()
        .navigationTitle("SubscriptionStoreView")
        .inlineNavigationTitle()
        .safeAreaInset(edge: .top) { sectionFilterBar }
        .sheet(isPresented: $showAppearanceSheet) { appearanceSheet }
        .sheet(isPresented: $showContainerSheet) { containerSheet }
        .sheet(isPresented: $showUICustomSheet) { uiCustomSheet }
        .sheet(isPresented: $showCustomControlSheet) { customControlSheet }
        .sheet(isPresented: $showAccessorySheet) { accessorySheet }
        .sheet(isPresented: $showStructureSheet) { structureSheet }
        .sheet(isPresented: $showInitSheet) { initializerSheet }
        .sheet(isPresented: $showOffersSheet) { subscriptionOffersSheet }
        .sheet(isPresented: $showPolicySheet) { policySheet }
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
            await store.reconcile()
        }
        .subscriptionStatusTask(for: groupID) { taskState in
            if case .success(let statuses) = taskState {
                subscriptionStatuses = statuses
            }
        }
        .task {
            loadedProducts = (try? await Product.products(for: [
                "com.storekitflow.demo.pro.monthly",
                "com.storekitflow.demo.pro.yearly",
                "com.storekitflow.demo.basic.monthly",
                "com.storekitflow.demo.basic.yearly"
            ])) ?? []
        }
    }

    private var sectionFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedSection == nil) { selectedSection = nil }
                ForEach(SSVSection.allCases) { section in
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

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            Picker("subscriptionStoreControlStyle", selection: $controlStyle) {
                ForEach(SubscriptionControlStyleOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("Layout of the plan selector — prominentPicker, picker, compactPicker, or buttons")
            Picker("subscriptionStoreControlBackground", selection: $controlBackground) {
                ForEach(ControlBackgroundOption.allCases) { Text($0.label).tag($0) }
            }
            .hint(".automatic adapts to light/dark mode, .clear removes the panel background")
            Picker("subscriptionStoreButtonLabel", selection: $buttonLabel) {
                ForEach(ButtonLabelOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("Text shown on the subscribe button — action, displayName, price, or multiline")
            if #available(iOS 18.0, *) {
                Picker("subscriptionStoreControlStyle placement", selection: $controlPlacement) {
                    ForEach(ControlPlacementOption.allCases) { Text($0.label).tag($0) }
                }
                .hint("iOS 18+ — where the control is placed within the store view (.automatic or .bottomBar)")
            }
            Toggle("Custom marketingContent: header", isOn: $showMarketingHeader)
                .hint("Replaces the default header above the plan list with a custom view")
            Button { showAppearanceSheet = true } label: {
                Label("Preview Appearance", systemImage: "paintbrush.fill")
            }
        } header: {
            Label("Appearance", systemImage: "paintbrush.fill")
        } footer: {
            InfoBox {
                InfoItem.group(".subscriptionStoreControlStyle", variants: [
                    (".prominentPicker", "large card-style picker — highlighted selection"),
                    (".picker",          "standard compact picker"),
                    (".compactPicker",   "segmented-style compact picker"),
                    (".buttons",         "one button per plan — no picker")
                ])
                InfoItem.group(".subscriptionStoreControlBackground", variants: [
                    (".automatic", "adapts panel background to light/dark mode"),
                    (".clear",     "removes panel background entirely")
                ])
                InfoItem.group(".subscriptionStoreButtonLabel", variants: [
                    (".action",      "shows 'Subscribe' on the button"),
                    (".displayName", "shows plan name (e.g. 'Monthly')"),
                    (".price",       "shows price (e.g. '$4.99')"),
                    (".multiline",   "stacks plan name and price")
                ])
                InfoItem.api("marketingContent:", "custom header view shown above the plan list")
                InfoItem.api(".subscriptionStoreControlStyle(_:placement:)", "iOS 18+ — overload that also specifies where the controls appear within the store view")
                InfoItem.group("placement", variants: [
                    (".automatic", "system-default placement"),
                    (".bottomBar", "controls pinned to the bottom of the view")
                ])
            }
        }
    }

    @ViewBuilder
    private var appearanceSheet: some View {
        let header = { AnyView(showMarketingHeader ? AnyView(paywallHeader) : AnyView(EmptyView())) }
        if #available(iOS 18.0, *) {
            let baseModifiers = { (style: String) -> [String] in
                var lines = ["SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)"]
                lines.append("  .subscriptionStoreControlStyle(.\(style))")
                lines.append("  .subscriptionStoreControlBackground(.\(controlBackground.rawValue))")
                lines.append("  .subscriptionStoreButtonLabel(.\(buttonLabel.rawValue))")
                if showMarketingHeader { lines.append("  // + marketingContent: { ... }") }
                return lines
            }
            PreviewSheet(
                title: "Appearance",
                modifiers: appearanceModifiers,
                variants: [
                    PreviewSheetVariant(
                        label: ".prominentPicker",
                        modifiers: baseModifiers("prominentPicker"),
                        content: AnyView(
                            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                                .subscriptionStoreControlStyle(.prominentPicker, placement: .automatic)
                                .applyControlBackground(controlBackground)
                                .applyButtonLabel(buttonLabel)
                        )
                    ),
                    PreviewSheetVariant(
                        label: ".picker",
                        modifiers: baseModifiers("picker"),
                        content: AnyView(
                            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                                .subscriptionStoreControlStyle(.picker, placement: .automatic)
                                .applyControlBackground(controlBackground)
                                .applyButtonLabel(buttonLabel)
                        )
                    ),
                    PreviewSheetVariant(
                        label: ".compactPicker",
                        modifiers: baseModifiers("compactPicker"),
                        content: AnyView(
                            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                                .subscriptionStoreControlStyle(.compactPicker, placement: controlPlacement == .bottomBar ? .bottomBar : .automatic)
                                .applyControlBackground(controlBackground)
                                .applyButtonLabel(buttonLabel)
                        )
                    ),
                    PreviewSheetVariant(
                        label: ".buttons",
                        modifiers: baseModifiers("buttons"),
                        content: AnyView(
                            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                                .subscriptionStoreControlStyle(.buttons, placement: .automatic)
                                .applyControlBackground(controlBackground)
                                .applyButtonLabel(buttonLabel)
                        )
                    ),
                ]
            ) { EmptyView() }
        } else {
            PreviewSheet(title: "Appearance", modifiers: appearanceModifiers) {
                switch controlStyle {
                case .buttons:
                    SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                        .subscriptionStoreControlStyle(.buttons)
                        .applyControlBackground(controlBackground)
                        .applyButtonLabel(buttonLabel)
                case .picker, .prominentPicker, .compactPicker:
                    SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                        .subscriptionStoreControlStyle(.prominentPicker)
                        .applyControlBackground(controlBackground)
                        .applyButtonLabel(buttonLabel)
                }
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

    // MARK: - Container Background (iOS 18+)

    @available(iOS 18.0, *)
    private var containerBackgroundSection: some View {
        Section {
            Picker("Placement", selection: $containerPlacement) {
                ForEach(ContainerPlacementOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("Where the background is applied — store, header only, or full screen height")
            Picker("Color", selection: $containerColor) {
                ForEach(ContainerColorOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("Gradient color applied to the containerBackground")
            Button { showContainerSheet = true } label: {
                Label("Preview Container Background", systemImage: "rectangle.fill.on.rectangle.fill")
            }
        } header: {
            Label("containerBackground", systemImage: "rectangle.fill.on.rectangle.fill")
        } footer: {
            InfoBox {
                InfoItem.group(".containerBackground(_:for:)", variants: [
                    (".subscriptionStore",           "fills the entire SubscriptionStoreView background"),
                    (".subscriptionStoreHeader",     "fills only the marketing header area"),
                    (".subscriptionStoreFullHeight", "extends background to full screen height including safe area")
                ])
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var containerSheet: some View {
        if #available(iOS 18.0, *) {
            let makeContent = { (placement: ContainerPlacementOption) -> AnyView in
                AnyView(
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
                    .applyContainerBackground(color: containerColor.color, placement: placement)
                )
            }
            PreviewSheet(
                title: "containerBackground",
                modifiers: containerModifiers,
                variants: [
                    PreviewSheetVariant(
                        label: ".store",
                        modifiers: ["  .containerBackground(\(containerColor.rawValue).gradient, for: .subscriptionStore)"],
                        content: makeContent(.subscriptionStore)
                    ),
                    PreviewSheetVariant(
                        label: ".header",
                        modifiers: ["  .containerBackground(\(containerColor.rawValue).gradient, for: .subscriptionStoreHeader)"],
                        content: makeContent(.subscriptionStoreHeader)
                    ),
                    PreviewSheetVariant(
                        label: ".fullHeight",
                        modifiers: ["  .containerBackground(\(containerColor.rawValue).gradient, for: .subscriptionStoreFullHeight)"],
                        content: makeContent(.subscriptionStoreFullHeight)
                    ),
                ]
            ) { EmptyView() }
        }
    }

    // MARK: - UI Customization (iOS 18+)

    @available(iOS 18.0, *)
    private var uiCustomizationSection: some View {
        Section {
            Picker("subscriptionStorePickerItemBackground", selection: $pickerItemBg) {
                ForEach(PickerItemBgOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("Background material behind each picker row — regularMaterial, thinMaterial, or clear")
            Toggle("Custom subscriptionStoreControlIcon", isOn: $useCustomIcon)
                .hint("Replaces the default icon in the control area with a custom view")
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
            PreviewSheet(title: "UI Customization", modifiers: uiCustomModifiers) {
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)
                    .subscriptionStoreControlStyle(.picker)
                    .applyPickerItemBackground(pickerItemBg)
                    .applyCustomIconIfNeeded(useCustomIcon)
            }
        }
    }

    // MARK: - Custom Controls (iOS 18+)

    @available(iOS 18.0, *)
    private var customControlsSection: some View {
        Section {
            Picker("Accent color", selection: $accentColor) {
                ForEach(AccentColorOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("Tint color applied to selected state and the subscribe button")
            Toggle("Show family sharing badge", isOn: $showFamilyBadge)
                .hint("Displays a family sharing badge on plans with isFamilyShareable = true")
            Picker("Button label", selection: $customButtonLabel) {
                ForEach(ButtonLabelOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("Label style for SubscriptionStoreButton — action, displayName, price, or multiline")
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
            PreviewSheet(title: "Custom Controls", modifiers: customControlModifiers) {
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
    }

    // MARK: - Accessory (iOS 18+)

    @available(iOS 18.0, *)
    private var accessorySection: some View {
        Section {
            Toggle("Restore Purchases", isOn: $showRestorePurchases)
                .hint(".storeButton(.visible, for: .restorePurchases)")
            Toggle("Sign In", isOn: $showSignIn)
                .hint(".storeButton(.visible, for: .signIn)")
            Toggle("Redeem Code", isOn: $showRedeemCode)
                .hint(".storeButton(.visible, for: .redeemCode)")
            Toggle("Policies", isOn: $showPolicies)
                .hint(".storeButton(.visible, for: .policies)")
            Toggle("Custom subscriptionStoreSignInAction", isOn: $useSignInAction)
                .hint("Registers a closure to handle the sign-in tap — present your own auth flow")
            Button { showAccessorySheet = true } label: {
                Label("Preview — tap to see changes", systemImage: "ellipsis.circle.fill")
            }
        } header: {
            Label("Accessory & Utility", systemImage: "ellipsis.circle.fill")
        } footer: {
            InfoBox {
                InfoItem.group(".storeButton(.visible, for:)", variants: [
                    (".restorePurchases", "shows the 'Restore Purchases' button"),
                    (".signIn",           "shows a sign-in button for unauthenticated users"),
                    (".redeemCode",       "shows a 'Redeem Code' entry point"),
                    (".policies",         "shows privacy policy and terms of service links")
                ])
                InfoItem.api(".subscriptionStoreSignInAction {}", "closure called when the sign-in button is tapped — present your own auth flow")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var accessorySheet: some View {
        if #available(iOS 18.0, *) {
            PreviewSheet(title: "Accessory", modifiers: accessoryModifiers) {
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)
                    .storeButton(showRestorePurchases ? .visible : .hidden, for: .restorePurchases)
                    .storeButton(showSignIn ? .visible : .hidden, for: .signIn)
                    .storeButton(showRedeemCode ? .visible : .hidden, for: .redeemCode)
                    .storeButton(showPolicies ? .visible : .hidden, for: .policies)
                    .applySignInActionIfNeeded(useSignInAction)
            }
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

    // MARK: - Initializers

    private var initializerSection: some View {
        Section {
            Picker("Source", selection: $initSource) {
                ForEach(InitSourceOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("How SubscriptionStoreView loads products — by group ID, product IDs, or pre-fetched Product values")
            Toggle("Custom marketingContent header", isOn: $useMarketingContent)
                .hint("Switches between marketingContent: init (custom header) and the automatic-header variant")
            if #available(iOS 18.0, *) {
                Toggle("Use @StoreContentBuilder (iOS 18+)", isOn: $useStoreContent)
                    .hint("Switches to the content: @StoreContentBuilder init for structured plan hierarchies")
            }
            if initSource == .subscriptions && loadedProducts.isEmpty {
                Text("Products not yet loaded — open sheet once they load.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button { showInitSheet = true } label: {
                Label("Open SubscriptionStoreView", systemImage: "play.circle.fill")
            }
        } header: {
            Label("Initializers", systemImage: "function")
        } footer: {
            InfoBox {
                InfoItem.group("init(groupID:visibleRelationships:)", variants: [
                    ("marketingContent:", "custom SwiftUI header above the plan list"),
                    ("(no marketingContent)", "uses AutomaticSubscriptionStoreMarketingContent"),
                    ("content: @StoreContentBuilder", "iOS 18+ — structured plan hierarchy")
                ])
                InfoItem.group("init(productIDs:)", variants: [
                    ("marketingContent:", "load specific IDs with a custom header"),
                    ("content: @StoreContentBuilder", "iOS 18+ — structured layout from ID list")
                ])
                InfoItem.group("init(subscriptions:)", variants: [
                    ("marketingContent:", "pass pre-fetched Product values with custom header"),
                    ("content: @StoreContentBuilder", "iOS 18+ — structured layout from Product values")
                ])
            }
        }
    }

    @ViewBuilder
    private var initializerSheet: some View {
        let productIDs = [
            "com.storekitflow.demo.pro.monthly",
            "com.storekitflow.demo.pro.yearly",
            "com.storekitflow.demo.basic.monthly",
            "com.storekitflow.demo.basic.yearly"
        ]
        let header = { AnyView(useMarketingContent ? AnyView(paywallHeader) : AnyView(EmptyView())) }

        if #available(iOS 18.0, *), useStoreContent {
            switch initSource {
            case .groupID:
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all) {
                    SubscriptionPeriodGroupSet()
                }
            case .productIDs:
                SubscriptionStoreView(productIDs: productIDs) {
                    SubscriptionPeriodGroupSet()
                }
            case .subscriptions:
                if loadedProducts.isEmpty {
                    ContentUnavailableView("Loading Products", systemImage: "arrow.clockwise")
                } else {
                    SubscriptionStoreView(subscriptions: loadedProducts) {
                        SubscriptionPeriodGroupSet()
                    }
                }
            }
        } else if useMarketingContent {
            switch initSource {
            case .groupID:
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
            case .productIDs:
                SubscriptionStoreView(productIDs: productIDs, marketingContent: header)
            case .subscriptions:
                if loadedProducts.isEmpty {
                    ContentUnavailableView("Loading Products", systemImage: "arrow.clockwise")
                } else {
                    SubscriptionStoreView(subscriptions: loadedProducts, marketingContent: header)
                }
            }
        } else {
            switch initSource {
            case .groupID:
                SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)
            case .productIDs:
                SubscriptionStoreView(productIDs: productIDs)
            case .subscriptions:
                if loadedProducts.isEmpty {
                    ContentUnavailableView("Loading Products", systemImage: "arrow.clockwise")
                } else {
                    SubscriptionStoreView(subscriptions: loadedProducts)
                }
            }
        }
    }

    // MARK: - Subscription Offers

    private var subscriptionOffersSection: some View {
        Section {
            Picker("visibleRelationships", selection: $visibleRelationship) {
                ForEach(SubscriptionRelationshipOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("Filters which plans are shown when the user already has an active subscription")
            if #available(iOS 18.0, *) {
                Toggle("preferredSubscriptionOffer (iOS 18+)", isOn: $applyPreferredOffer)
                    .hint("Selects the first eligible offer for each plan — eligibleOffers only contains offers the user qualifies for")
            }
            if #available(iOS 26.0, *) {
                Toggle("subscriptionIntroductoryOffer (iOS 26+)", isOn: $applyIntroOffer)
                    .hint("Applies a JWS-signed introductory offer to eligible subscribers — signature generated server-side")
            }
            Button { showOffersSheet = true } label: {
                Label("Preview with Offer Settings", systemImage: "tag.circle.fill")
            }
        } header: {
            Label("Subscription Offers", systemImage: "tag.circle.fill")
        } footer: {
            InfoBox {
                InfoItem.group("visibleRelationships", variants: [
                    (".all",        "shows all plans regardless of current subscription"),
                    (".current",    "shows only the plan the user is currently subscribed to"),
                    (".upgrade",    "shows only plans with a higher level of service"),
                    (".downgrade",  "shows only plans with a lower level of service"),
                    (".crossgrade", "shows plans at the same level but different duration or type")
                ])
                InfoItem.api(".subscriptionPromotionalOffer(offer:compactJWS:)", "iOS 26+ — selects a promo offer to apply; system shows discounted terms in UI and signs the purchase with your JWS")
                InfoItem.api(".subscriptionPromotionalOffer(offer:signature:)", "iOS 17.4–26 — deprecated variant using the older Signature type instead of compact JWS")
                InfoItem.api(".subscriptionIntroductoryOffer(applyOffer:compactJWS:)", "iOS 26+ — controls whether the introductory offer is applied; your server returns a JWS to validate eligibility")
                InfoItem.api(".preferredSubscriptionOffer { product, subscription, eligibleOffers in … }", "iOS 18+ — called before drawing each plan; return an offer from eligibleOffers to apply discounted terms in the UI")
                InfoItem.note("eligibleOffers contains only offers the customer qualifies for — unlike subscriptionInfo.subscriptionOffers which may include ineligible ones.")
                InfoItem.note("Promotional and introductory offer modifiers require server-side JWS signing — this demo shows visibleRelationships and the introductory offer toggle (sandbox only).")
            }
        }
    }

    @ViewBuilder
    private var subscriptionOffersSheet: some View {
        PreviewSheet(title: "Subscription Offers", modifiers: offersModifiers) {
            if #available(iOS 26.0, *), applyIntroOffer {
                SubscriptionStoreView(groupID: groupID, visibleRelationships: visibleRelationship.value)
                    .applyPreferredOfferIfNeeded(applyPreferredOffer)
                    .subscriptionIntroductoryOffer(
                        applyOffer: { _, _ in true },
                        compactJWS: { _, _ in throw URLError(.badURL) }
                    )
            } else if #available(iOS 18.0, *), applyPreferredOffer {
                SubscriptionStoreView(groupID: groupID, visibleRelationships: visibleRelationship.value)
                    .preferredSubscriptionOffer { _, _, eligible in eligible.first }
            } else {
                SubscriptionStoreView(groupID: groupID, visibleRelationships: visibleRelationship.value)
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
            .hint("Layout style applied to the SubscriptionPeriodGroupSet structure")
            Picker("subscriptionStoreOptionGroupStyle", selection: $optionGroupStyle) {
                ForEach(OptionGroupStyleOption.allCases) { Text($0.label).tag($0) }
            }
            .hint("How top-level option groups are presented — .automatic, .tabs (tab bar), or .links (navigation links)")
            Toggle("Custom marketing header", isOn: $structureShowHeader)
                .hint("Shows a custom header above the grouped plan structure")
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
                InfoItem.group(".subscriptionStoreOptionGroupStyle", variants: [
                    (".automatic", "system-default presentation for groups"),
                    (".tabs",      "top-level groups shown as tabs in a tab bar"),
                    (".links",     "first group shown with links to navigate to other groups")
                ])
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var structureSheet: some View {
        if #available(iOS 18.0, *) {
            let header = { AnyView(structureShowHeader ? AnyView(structureHeader) : AnyView(EmptyView())) }
            let makeContent = { (groupStyle: OptionGroupStyleOption) -> AnyView in
                let view: any View
                switch structureControlStyle {
                case .buttons:
                    view = SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                        .subscriptionStoreControlStyle(.buttons)
                        .applyOptionGroupStyle(groupStyle)
                case .picker:
                    view = SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                        .subscriptionStoreControlStyle(.picker)
                        .applyOptionGroupStyle(groupStyle)
                case .prominentPicker:
                    view = SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                        .subscriptionStoreControlStyle(.prominentPicker)
                        .applyOptionGroupStyle(groupStyle)
                case .compactPicker:
                    view = SubscriptionStoreView(groupID: groupID, visibleRelationships: .all, marketingContent: header)
                        .subscriptionStoreControlStyle(.compactPicker)
                        .applyOptionGroupStyle(groupStyle)
                }
                return AnyView(view)
            }
            PreviewSheet(
                title: "Structure",
                modifiers: structureModifiers,
                variants: [
                    PreviewSheetVariant(
                        label: ".automatic",
                        modifiers: ["  .subscriptionStoreOptionGroupStyle(.automatic)"],
                        content: makeContent(.automatic)
                    ),
                    PreviewSheetVariant(
                        label: ".tabs",
                        modifiers: ["  .subscriptionStoreOptionGroupStyle(.tabs)"],
                        content: makeContent(.tabs)
                    ),
                    PreviewSheetVariant(
                        label: ".links",
                        modifiers: ["  .subscriptionStoreOptionGroupStyle(.links)"],
                        content: makeContent(.links)
                    ),
                ]
            ) { EmptyView() }
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
    // MARK: - Policy

    private var policySection: some View {
        Section {
            Toggle("Show Privacy Policy button", isOn: $showPrivacyPolicy)
                .hint(".subscriptionStorePolicyDestination(url:for: .privacyPolicy)")
            Toggle("Show Terms of Service button", isOn: $showTermsOfService)
                .hint(".subscriptionStorePolicyDestination(url:for: .termsOfService)")
            Picker("Policy button color", selection: $policyColor) {
                ForEach(PolicyColorOption.allCases) { Text($0.label).tag($0) }
            }
            .hint(".subscriptionStorePolicyForegroundStyle — tint applied to both policy buttons")
            Button { showPolicySheet = true } label: {
                Label("Preview Policy Buttons", systemImage: "doc.text.fill")
            }
        } header: {
            Label("Policy", systemImage: "doc.text.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".subscriptionStorePolicyDestination(url:for: .privacyPolicy)", "sets the URL opened when the user taps the Privacy Policy button")
                InfoItem.api(".subscriptionStorePolicyDestination(url:for: .termsOfService)", "sets the URL opened when the user taps the Terms of Service button")
                InfoItem.api(".subscriptionStorePolicyDestination(for:destination:)", "alternative: present a custom SwiftUI view instead of opening a URL")
                InfoItem.api(".subscriptionStorePolicyForegroundStyle(_:)", "sets the foreground color of both policy buttons")
                InfoItem.api(".subscriptionStorePolicyForegroundStyle(_:_:)", "sets primary (button text) and secondary (conjunction) colors separately")
                InfoItem.note("At least one policy destination must be set for the policy buttons to appear by default. Use .storeButton(.visible, for: .policies) to force visibility.")
            }
        }
    }

    @ViewBuilder
    private var policySheet: some View {
        let privacyURL = URL(string: "https://example.com/privacy")!
        let termsURL = URL(string: "https://example.com/terms")!
        PreviewSheet(title: "Policy", modifiers: policyModifiers) {
            SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)
                .applyPolicyDestinations(privacy: showPrivacyPolicy ? privacyURL : nil, terms: showTermsOfService ? termsURL : nil)
                .subscriptionStorePolicyForegroundStyle(policyColor.color)
                .storeButton(.visible, for: .policies)
        }
    }
}

// MARK: - Modifier Computed Vars

extension SKSubscriptionStoreViewScreen {
    fileprivate var appearanceModifiers: [String] {
        var lines = ["SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)"]
        lines.append("  .subscriptionStoreControlStyle(.\(controlStyle.rawValue))")
        lines.append("  .subscriptionStoreControlBackground(.\(controlBackground.rawValue))")
        lines.append("  .subscriptionStoreButtonLabel(.\(buttonLabel.rawValue))")
        if showMarketingHeader { lines.append("  // + marketingContent: { YourHeaderView() }") }
        return lines
    }

    fileprivate var containerModifiers: [String] {
        ["SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)",
         "  .containerBackground(\(containerColor.rawValue).gradient, for: .\(containerPlacement.rawValue))"]
    }

    fileprivate var uiCustomModifiers: [String] {
        var lines = ["SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)",
                     "  .subscriptionStoreControlStyle(.picker)",
                     "  .subscriptionStorePickerItemBackground(.\(pickerItemBg.rawValue))"]
        if useCustomIcon { lines.append("  .subscriptionStoreControlIcon { _, _ in Image(systemName: \"star.circle.fill\") }") }
        return lines
    }

    fileprivate var customControlModifiers: [String] {
        ["SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)",
         "  .subscriptionStoreControlStyle(SSVCustomPickerStyle(",
         "      accentColor: \(accentColor.rawValue),",
         "      showFamilyBadge: \(showFamilyBadge)))"]
    }

    fileprivate var accessoryModifiers: [String] {
        var lines = ["SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)"]
        if showRestorePurchases { lines.append("  .storeButton(.visible, for: .restorePurchases)") }
        if showSignIn           { lines.append("  .storeButton(.visible, for: .signIn)") }
        if showRedeemCode       { lines.append("  .storeButton(.visible, for: .redeemCode)") }
        if showPolicies         { lines.append("  .storeButton(.visible, for: .policies)") }
        if useSignInAction      { lines.append("  .subscriptionStoreSignInAction { /* present auth */ }") }
        return lines
    }

    fileprivate var structureModifiers: [String] {
        ["SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)",
         "  .subscriptionStoreControlStyle(.\(structureControlStyle.rawValue))",
         "  .subscriptionStoreOptionGroupStyle(.\(optionGroupStyle.rawValue))",
         "  // content: { SubscriptionPeriodGroupSet() }"]
    }

    fileprivate var offersModifiers: [String] {
        var lines = ["SubscriptionStoreView(groupID: groupID, visibleRelationships: .\(visibleRelationship.rawValue))"]
        if applyPreferredOffer { lines.append("  .preferredSubscriptionOffer { _, _, eligible in eligible.first }") }
        if applyIntroOffer     { lines.append("  .subscriptionIntroductoryOffer(applyOffer: { _, _ in true }, compactJWS: { ... })") }
        return lines
    }

    fileprivate var policyModifiers: [String] {
        var lines = ["SubscriptionStoreView(groupID: groupID, visibleRelationships: .all)"]
        if showPrivacyPolicy  { lines.append("  .subscriptionStorePolicyDestination(url: privacyURL, for: .privacyPolicy)") }
        if showTermsOfService { lines.append("  .subscriptionStorePolicyDestination(url: termsURL, for: .termsOfService)") }
        lines.append("  .subscriptionStorePolicyForegroundStyle(.\(policyColor.rawValue))")
        lines.append("  .storeButton(.visible, for: .policies)")
        return lines
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
                        .fill(option.isSelected ? accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
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
            self.subscriptionStoreControlIcon { _, _ in
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

    @available(iOS 18.0, *)
    @ViewBuilder
    func applyOptionGroupStyle(_ option: SKSubscriptionStoreViewScreen.OptionGroupStyleOption) -> some View {
        switch option {
        case .automatic: self.subscriptionStoreOptionGroupStyle(.automatic)
        case .tabs:      self.subscriptionStoreOptionGroupStyle(.tabs)
        case .links:     self.subscriptionStoreOptionGroupStyle(.links)
        }
    }

    @available(iOS 18.0, *)
    @ViewBuilder
    func applyPreferredOfferIfNeeded(_ enabled: Bool) -> some View {
        if enabled {
            self.preferredSubscriptionOffer { _, _, eligible in eligible.first }
        } else {
            self
        }
    }

    @ViewBuilder
    func applyPolicyDestinations(privacy: URL?, terms: URL?) -> some View {
        if let privacy, let terms {
            self
                .subscriptionStorePolicyDestination(url: privacy, for: .privacyPolicy)
                .subscriptionStorePolicyDestination(url: terms, for: .termsOfService)
        } else if let privacy {
            self.subscriptionStorePolicyDestination(url: privacy, for: .privacyPolicy)
        } else if let terms {
            self.subscriptionStorePolicyDestination(url: terms, for: .termsOfService)
        } else {
            self
        }
    }
}

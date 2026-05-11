import SwiftUI
import StoreKit

struct SKStylingDemoScreen: View {
    // State lifted to stable root — prevents sheet dismiss bug in List
    @State private var productStyle: ProductViewStyleOption = .regular
    @State private var productIconBorder = false
    @State private var showProductSheet = false

    @State private var subscriptionControlStyle: SubscriptionControlStyleOption = .prominentPicker
    @State private var controlBackground: ControlBackgroundOption = .automatic
    @State private var buttonLabel: ButtonLabelOption = .action
    @State private var showSubscriptionSheet = false

    // UI Customization
    @State private var pickerItemBackground: PickerItemBackgroundOption = .regularMaterial
    @State private var useCustomControlIcon = false
    @State private var showUICustomSheet = false

    // Container Background
    @State private var containerPlacement: ContainerPlacementOption = .subscriptionStore
    @State private var containerColor: ContainerColorOption = .blue
    @State private var showContainerSheet = false

    // Accessory
    @State private var showRestorePurchases = true
    @State private var showSignIn = false
    @State private var showRedeemCode = false
    @State private var showPolicies = true
    @State private var useCustomSignInAction = false
    @State private var showAccessorySheet = false

    private var coinIcon: some View {
        Image(systemName: "circle.grid.3x3.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .padding(10)
            .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 14))
    }

    var body: some View {
        List {
            productViewStyleSection
            subscriptionStoreStylingSection
            if #available(iOS 18.0, *) {
                uiCustomizationSection
                containerBackgroundSection
                accessorySection
            } else {
                Section {
                    ContentUnavailableView(
                        "More options on iOS 18",
                        systemImage: "exclamationmark.triangle",
                        description: Text("UI Customization, Container Background, and Accessory sections require iOS 18 or later.")
                    )
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listSectionSpacing(12)
        .navigationTitle("Styling")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProductSheet) { productSheet }
        .sheet(isPresented: $showSubscriptionSheet) { subscriptionSheet }
        .sheet(isPresented: $showUICustomSheet) { uiCustomSheet }
        .sheet(isPresented: $showContainerSheet) { containerSheet }
        .sheet(isPresented: $showAccessorySheet) { accessorySheet }
    }

    // MARK: - ProductViewStyle

    private var productViewStyleSection: some View {
        Section {
            Picker("productViewStyle", selection: $productStyle) {
                ForEach(ProductViewStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("productIconBorder()", isOn: $productIconBorder)

            switch productStyle {
            case .regular:
                ProductView(id: "com.storekitflow.demo.coins10") {
                    coinIcon.applyBorderIfNeeded(productIconBorder)
                }
                .productViewStyle(.regular)
            case .compact:
                ProductView(id: "com.storekitflow.demo.coins10") {
                    coinIcon.applyBorderIfNeeded(productIconBorder)
                }
                .productViewStyle(.compact)
            case .large:
                Button { showProductSheet = true } label: {
                    Label("Preview .large style", systemImage: "arrow.up.square")
                }
            }
        } header: {
            Label("ProductViewStyle", systemImage: "cube.box")
        } footer: {
            InfoBox {
                InfoItem.api(".productViewStyle(.large)", "hero card — best presented in a sheet")
                InfoItem.api(".productViewStyle(.regular)", "standard row — shown inline in a list")
                InfoItem.api(".productViewStyle(.compact)", "dense row — space-efficient layouts")
                InfoItem.api(".productIconBorder()", "applies Apple's standard rounded border to custom icons")
            }
        }
    }

    @ViewBuilder
    private var productSheet: some View {
        NavigationStack {
            VStack {
                Spacer()
                ProductView(id: "com.storekitflow.demo.coins10") {
                    coinIcon.applyBorderIfNeeded(productIconBorder)
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

    // MARK: - SubscriptionStoreView Styling

    private var subscriptionStoreStylingSection: some View {
        Section {
            Picker("subscriptionStoreControlStyle", selection: $subscriptionControlStyle) {
                ForEach(SubscriptionControlStyleOption.allCases) { Text($0.label).tag($0) }
            }
            Picker("subscriptionStoreControlBackground", selection: $controlBackground) {
                ForEach(ControlBackgroundOption.allCases) { Text($0.label).tag($0) }
            }
            Picker("subscriptionStoreButtonLabel", selection: $buttonLabel) {
                ForEach(ButtonLabelOption.allCases) { Text($0.label).tag($0) }
            }
            Button { showSubscriptionSheet = true } label: {
                Label("Preview Styling", systemImage: "paintbrush.fill")
            }
        } header: {
            Label("SubscriptionStoreView Styling", systemImage: "paintbrush.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".subscriptionStoreControlStyle()", ".buttons / .picker / .prominentPicker / .compactPicker")
                InfoItem.api(".subscriptionStoreControlBackground(.automatic)", "adapts panel to light/dark mode")
                InfoItem.api(".subscriptionStoreControlBackground(.clear)", "removes the panel background entirely")
                InfoItem.api(".subscriptionStoreButtonLabel(.action)", "shows 'Subscribe'")
                InfoItem.api(".subscriptionStoreButtonLabel(.displayName)", "shows the plan name")
                InfoItem.api(".subscriptionStoreButtonLabel(.price)", "shows the price")
                InfoItem.api(".subscriptionStoreButtonLabel(.multiline)", "stacks name + price")
            }
        }
    }

    @ViewBuilder
    private var subscriptionSheet: some View {
        let base = SubscriptionStoreView(groupID: "763D6759")
        Group {
            switch subscriptionControlStyle {
            case .buttons:         base.subscriptionStoreControlStyle(.buttons)
            case .picker:          base.subscriptionStoreControlStyle(.picker)
            case .prominentPicker: base.subscriptionStoreControlStyle(.prominentPicker)
            case .compactPicker:   base.subscriptionStoreControlStyle(.compactPicker)
            }
        }
        .applyControlBackground(controlBackground)
        .applyButtonLabel(buttonLabel)
    }

    // MARK: - UI Customization (iOS 18+)

    @available(iOS 18.0, *)
    private var uiCustomizationSection: some View {
        Section {
            Picker("subscriptionStorePickerItemBackground", selection: $pickerItemBackground) {
                ForEach(PickerItemBackgroundOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Custom subscriptionStoreControlIcon", isOn: $useCustomControlIcon)
            Button { showUICustomSheet = true } label: {
                Label("Preview UI Customization", systemImage: "slider.vertical.3")
            }
        } header: {
            Label("UI Customization", systemImage: "slider.vertical.3")
        } footer: {
            InfoBox {
                InfoItem.api(".subscriptionStorePickerItemBackground(.regularMaterial)", "frosted-glass material background for each picker row")
                InfoItem.api(".subscriptionStorePickerItemBackground(.thinMaterial)", "thinner frosted-glass effect for each row")
                InfoItem.api(".subscriptionStorePickerItemBackground(Color.clear)", "no background — fully transparent rows")
                InfoItem.api(".subscriptionStoreControlIcon(_:)", "replaces the default icon shown in the control area with a custom view")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var uiCustomSheet: some View {
        if #available(iOS 18.0, *) {
            SubscriptionStoreView(groupID: "763D6759", visibleRelationships: .all)
                .subscriptionStoreControlStyle(.picker)
                .applyPickerItemBackground(pickerItemBackground)
                .applyControlIconIfNeeded(useCustomControlIcon)
        }
    }

    // MARK: - Container Background (iOS 18+)

    @available(iOS 18.0, *)
    private var containerBackgroundSection: some View {
        Section {
            Picker("containerBackground placement", selection: $containerPlacement) {
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
                InfoItem.api(".containerBackground(_:for: .subscriptionStoreFullHeight)", "extends the background to fill the full screen height including safe area")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var containerSheet: some View {
        if #available(iOS 18.0, *) {
            SubscriptionStoreView(groupID: "763D6759", visibleRelationships: .all) {
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

    // MARK: - Accessory (iOS 18+)

    @available(iOS 18.0, *)
    private var accessorySection: some View {
        Section {
            Toggle("Show Restore Purchases button", isOn: $showRestorePurchases)
            Toggle("Show Sign In button", isOn: $showSignIn)
            Toggle("Show Redeem Code button", isOn: $showRedeemCode)
            Toggle("Show Policies button", isOn: $showPolicies)
            Toggle("Custom subscriptionStoreSignInAction", isOn: $useCustomSignInAction)
            Button { showAccessorySheet = true } label: {
                Label("Preview Accessory Buttons", systemImage: "ellipsis.circle.fill")
            }
        } header: {
            Label("Accessory & Utility", systemImage: "ellipsis.circle.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".storeButton(.visible, for: .restorePurchases)", "shows the 'Restore Purchases' button in the store")
                InfoItem.api(".storeButton(.visible, for: .signIn)", "shows a sign-in button for non-authenticated users")
                InfoItem.api(".storeButton(.visible, for: .redeemCode)", "shows a 'Redeem Code' button")
                InfoItem.api(".storeButton(.visible, for: .policies)", "shows policy links (privacy, terms)")
                InfoItem.api(".subscriptionStoreSignInAction {}", "registers a closure to handle the sign-in tap — use to present your own auth flow")
            }
        }
    }

    @ViewBuilder
    private var accessorySheet: some View {
        if #available(iOS 18.0, *) {
            SubscriptionStoreView(groupID: "763D6759", visibleRelationships: .all)
                .applyStoreButtons(
                    restorePurchases: showRestorePurchases,
                    signIn: showSignIn,
                    redeemCode: showRedeemCode,
                    policies: showPolicies
                )
                .applySignInActionIfNeeded(useCustomSignInAction)
        }
    }
}

// MARK: - Enums

private enum ControlBackgroundOption: String, CaseIterable, Identifiable {
    case automatic, clear
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

private enum PickerItemBackgroundOption: String, CaseIterable, Identifiable {
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
    case blue, purple, green, orange
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .blue:   return .blue
        case .purple: return .purple
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
    func applyPickerItemBackground(_ option: PickerItemBackgroundOption) -> some View {
        switch option {
        case .regularMaterial: self.subscriptionStorePickerItemBackground(.regularMaterial)
        case .thinMaterial:    self.subscriptionStorePickerItemBackground(.thinMaterial)
        case .clear:           self.subscriptionStorePickerItemBackground(Color.clear)
        }
    }

    @available(iOS 18.0, *)
    @ViewBuilder
    func applyControlIconIfNeeded(_ custom: Bool) -> some View {
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
    func applyStoreButtons(restorePurchases: Bool, signIn: Bool, redeemCode: Bool, policies: Bool) -> some View {
        self
            .storeButton(restorePurchases ? .visible : .hidden, for: .restorePurchases)
            .storeButton(signIn ? .visible : .hidden, for: .signIn)
            .storeButton(redeemCode ? .visible : .hidden, for: .redeemCode)
            .storeButton(policies ? .visible : .hidden, for: .policies)
    }

    @available(iOS 18.0, *)
    @ViewBuilder
    func applySignInActionIfNeeded(_ enabled: Bool) -> some View {
        if enabled {
            self.subscriptionStoreSignInAction {
                // Custom sign-in handler — present your own auth flow here
            }
        } else {
            self
        }
    }
}

#Preview {
    NavigationStack {
        SKStylingDemoScreen()
    }
}

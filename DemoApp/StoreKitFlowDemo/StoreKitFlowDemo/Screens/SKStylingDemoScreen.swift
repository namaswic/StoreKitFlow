import SwiftUI
import StoreKit

struct SKStylingDemoScreen: View {
    var body: some View {
        List {
            ProductViewStyleSection()
            SubscriptionStoreStylingSection()
        }
        .listSectionSpacing(12)
        .navigationTitle("Styling")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ProductViewStyle + productIconBorder

private struct ProductViewStyleSection: View {
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
                ProductView(id: "com.storekitflow.demo.coins10") {
                    iconView.applyBorderIfNeeded(showIconBorder)
                }
                .productViewStyle(.regular)
            case .compact:
                ProductView(id: "com.storekitflow.demo.coins10") {
                    iconView.applyBorderIfNeeded(showIconBorder)
                }
                .productViewStyle(.compact)
            case .large:
                Button {
                    showLargeSheet = true
                } label: {
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
        .sheet(isPresented: $showLargeSheet) {
            NavigationStack {
                VStack {
                    Spacer()
                    ProductView(id: "com.storekitflow.demo.coins10") {
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
        Image(systemName: "circle.grid.3x3.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.white)
            .padding(10)
            .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - SubscriptionStoreView Styling

private struct SubscriptionStoreStylingSection: View {
    @State private var controlStyle: SubscriptionControlStyleOption = .prominentPicker
    @State private var controlBackground: ControlBackgroundOption = .automatic
    @State private var buttonLabel: ButtonLabelOption = .action
    @State private var showSheet = false

    var body: some View {
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
            Button {
                showSheet = true
            } label: {
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
        .sheet(isPresented: $showSheet) {
            styledView
        }
    }

    @ViewBuilder
    private var styledView: some View {
        let base = SubscriptionStoreView(groupID: "763D6759")
        Group {
            switch controlStyle {
            case .buttons:        base.subscriptionStoreControlStyle(.buttons)
            case .picker:         base.subscriptionStoreControlStyle(.picker)
            case .prominentPicker: base.subscriptionStoreControlStyle(.prominentPicker)
            case .compactPicker:  base.subscriptionStoreControlStyle(.compactPicker)
            }
        }
        .applyControlBackground(controlBackground)
        .applyButtonLabel(buttonLabel)
    }
}

private enum ControlBackgroundOption: String, CaseIterable, Identifiable {
    case automatic, clear
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

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
        case .action:       self.subscriptionStoreButtonLabel(.action)
        case .displayName:  self.subscriptionStoreButtonLabel(.displayName)
        case .price:        self.subscriptionStoreButtonLabel(.price)
        case .multiline:    self.subscriptionStoreButtonLabel(.multiline)
        }
    }
}

#Preview {
    NavigationStack {
        SKStylingDemoScreen()
    }
}

import SwiftUI
import StoreKit

struct SKControlsDemoScreen: View {
    // State lifted to stable root — prevents sheet dismiss bug in List
    @State private var accentColor: AccentColorOption = .purple
    @State private var showFamilyBadge = true
    @State private var buttonLabelStyle: ButtonLabelOption = .multiline
    @State private var showSheet = false

    var body: some View {
        List {
            if #available(iOS 18.0, *) {
                customControlSection
            } else {
                Section {
                    ContentUnavailableView(
                        "Requires iOS 18",
                        systemImage: "exclamationmark.triangle",
                        description: Text("SubscriptionStoreButton, SubscriptionStorePicker, and SubscriptionStorePickerOption require iOS 18 or later.")
                    )
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Controls")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSheet) { customSheet }
    }

    private var customControlSection: some View {
        Section {
            Picker("Accent color", selection: $accentColor) {
                ForEach(AccentColorOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Show family sharing badge", isOn: $showFamilyBadge)
            Picker("SubscriptionStoreButton label", selection: $buttonLabelStyle) {
                ForEach(ButtonLabelOption.allCases) { Text($0.label).tag($0) }
            }
            Button { showSheet = true } label: {
                Label("Open with Custom Control Style", systemImage: "slider.horizontal.3")
            }
        } header: {
            Label("SubscriptionStorePicker · SubscriptionStoreButton · SubscriptionStorePickerOption", systemImage: "slider.horizontal.3")
        } footer: {
            InfoBox {
                InfoItem.api("SubscriptionStorePicker", "lays out each plan option with a custom row view")
                InfoItem.api("SubscriptionStorePickerOption", "provides displayName, price, isSelected, isFamilyShareable per plan")
                InfoItem.api("SubscriptionStoreButton", "renders the confirm/subscribe action button")
                InfoItem.api(".subscriptionStoreControlStyle()", "applies your custom style to SubscriptionStoreView")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var customSheet: some View {
        if #available(iOS 18.0, *) {
            SubscriptionStoreView(groupID: "763D6759", visibleRelationships: .all) {
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
                CustomPickerControlStyle(
                    accentColor: accentColor.color,
                    showFamilyBadge: showFamilyBadge,
                    buttonLabelStyle: buttonLabelStyle
                )
            )
        }
    }
}

@available(iOS 18.0, *)
private struct CustomPickerControlStyle: SubscriptionStoreControlStyle {
    let accentColor: Color
    let showFamilyBadge: Bool
    let buttonLabelStyle: ButtonLabelOption

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 12) {
            SubscriptionStorePicker(configuration) { option in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(option.displayName)
                                .font(.headline)
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
                                .strokeBorder(option.isSelected ? accentColor : Color.clear, lineWidth: 2)
                        )
                )
            } confirmation: { option in
                switch buttonLabelStyle {
                case .action:       SubscriptionStoreButton(option).subscriptionStoreButtonLabel(.action).tint(accentColor)
                case .displayName:  SubscriptionStoreButton(option).subscriptionStoreButtonLabel(.displayName).tint(accentColor)
                case .price:        SubscriptionStoreButton(option).subscriptionStoreButtonLabel(.price).tint(accentColor)
                case .multiline:    SubscriptionStoreButton(option).subscriptionStoreButtonLabel(.multiline).tint(accentColor)
                }
            }
            .padding(.horizontal)
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

enum ButtonLabelOption: String, CaseIterable, Identifiable {
    case action, displayName, price, multiline
    var id: String { rawValue }
    var label: String { ".\(rawValue)" }
}

#Preview {
    NavigationStack {
        SKControlsDemoScreen()
    }
}

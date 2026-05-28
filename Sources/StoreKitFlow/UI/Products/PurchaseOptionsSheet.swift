import SwiftUI

struct PurchaseOptionsSheet: View {
    let product: StoreProduct
    @EnvironmentObject private var store: StoreKitFlowStore
    @Environment(\.dismiss) private var dismiss

    @State private var useAppAccountToken = false
    @State private var appAccountToken = UUID()
    @State private var quantity = 1
    @State private var simulatesAskToBuy = false
    @State private var stringEntries: [KVEntry<String>] = []
    @State private var doubleEntries: [KVEntry<Double>] = []
    @State private var boolEntries: [KVEntry<Bool>] = []
    @State private var introJWS = ""
    @State private var selectedWinBackOfferID: String = ""
    @State private var onStorefrontChange = false
    @State private var isPurchasing = false

    private var supportsQuantity: Bool {
        product.type == .consumable || product.type == .nonRenewing
    }

    private var hasWinBackOffers: Bool {
        !product.winBackOffers.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                if supportsQuantity { quantitySection }
                sandboxSection
                customMetadataSection
                offersSection
                storefrontSection
            }
            .navigationTitle(product.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            isPurchasing = true
                            await store.purchase(product, attributes: buildAttributes())
                            isPurchasing = false
                            dismiss()
                        }
                    } label: {
                        if isPurchasing {
                            ProgressView()
                        } else {
                            Text("Purchase")
                                .bold()
                        }
                    }
                    .disabled(isPurchasing)
                }
            }
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section {
            Toggle("Use App Account Token", isOn: $useAppAccountToken.animation())
            if useAppAccountToken {
                HStack {
                    Text(appAccountToken.uuidString)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer()
                    Button {
                        appAccountToken = UUID()
                    } label: {
                        Image(systemName: "dice")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Account")
        } footer: {
            Text("Links this purchase to your backend user account via Transaction.appAccountToken.")
        }
    }

    private var quantitySection: some View {
        Section {
            Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
        } header: {
            Text("Quantity")
        } footer: {
            Text("Only valid for consumables and non-renewing subscriptions.")
        }
    }

    private var sandboxSection: some View {
        Section("Sandbox") {
            Toggle("Simulate Ask to Buy", isOn: $simulatesAskToBuy)
        }
    }

    private var customMetadataSection: some View {
        Section {
            ForEach($stringEntries) { $entry in
                HStack(spacing: 8) {
                    TextField("Key", text: $entry.key)
                        .frame(maxWidth: 100)
                    Divider()
                    TextField("Value", text: $entry.stringValue)
                }
            }
            .onDelete { stringEntries.remove(atOffsets: $0) }
            Button("Add String Value") {
                stringEntries.append(KVEntry(key: "", stringValue: ""))
            }

            ForEach($doubleEntries) { $entry in
                HStack(spacing: 8) {
                    TextField("Key", text: $entry.key)
                        .frame(maxWidth: 100)
                    Divider()
                    TextField("Value", value: $entry.doubleValue, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            .onDelete { doubleEntries.remove(atOffsets: $0) }
            Button("Add Double Value") {
                doubleEntries.append(KVEntry(key: "", doubleValue: 0))
            }

            ForEach($boolEntries) { $entry in
                HStack(spacing: 8) {
                    TextField("Key", text: $entry.key)
                        .frame(maxWidth: 100)
                    Spacer()
                    Toggle("", isOn: $entry.boolValue)
                        .labelsHidden()
                }
            }
            .onDelete { boolEntries.remove(atOffsets: $0) }
            Button("Add Bool Value") {
                boolEntries.append(KVEntry(key: "", boolValue: false))
            }
        } header: {
            Text("Custom Metadata")
        } footer: {
            Text("Forwarded via Product.PurchaseOption.custom(key:value:). Readable server-side from the signed transaction.")
        }
    }

    private var offersSection: some View {
        Section {
            if hasWinBackOffers {
                Picker("Win-Back Offer", selection: $selectedWinBackOfferID) {
                    Text("None").tag("")
                    ForEach(product.winBackOffers, id: \.id) { offer in
                        Text("\(offer.id) — \(offer.displayPrice)").tag(offer.id)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Introductory Offer JWS")
                    .font(.subheadline)
                TextField("Compact JWS string from your server", text: $introJWS, axis: .vertical)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(3...6)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Offers")
        } footer: {
            Text("Win-back offers are iOS 18+ only. The JWS token is obtained from your server after verifying introductory offer eligibility.")
        }
    }

    private var storefrontSection: some View {
        Section {
            Toggle("On Storefront Change (no-op)", isOn: $onStorefrontChange)
        } header: {
            Text("Storefront")
        } footer: {
            Text("Registers a no-op .onStorefrontChange handler. Your app should register its own real handler at a higher level.")
        }
    }

    // MARK: - Build attributes

    private func buildAttributes() -> PurchaseAttributes {
        PurchaseAttributes(
            appAccountToken: useAppAccountToken ? appAccountToken : nil,
            quantity: supportsQuantity && quantity > 1 ? quantity : nil,
            simulatesAskToBuy: simulatesAskToBuy ? true : nil,
            customStringValues: Dictionary(uniqueKeysWithValues: stringEntries.filter { !$0.key.isEmpty }.map { ($0.key, $0.stringValue) }),
            customDoubleValues: Dictionary(uniqueKeysWithValues: doubleEntries.filter { !$0.key.isEmpty }.map { ($0.key, $0.doubleValue) }),
            customBoolValues: Dictionary(uniqueKeysWithValues: boolEntries.filter { !$0.key.isEmpty }.map { ($0.key, $0.boolValue) }),
            winBackOfferID: selectedWinBackOfferID.isEmpty ? nil : selectedWinBackOfferID,
            onStorefrontChange: onStorefrontChange,
            introductoryOfferJWS: introJWS.isEmpty ? nil : introJWS
        )
    }
}

// MARK: - KVEntry

private struct KVEntry<V>: Identifiable {
    let id = UUID()
    var key: String
    var stringValue: String = ""
    var doubleValue: Double = 0
    var boolValue: Bool = false

    init(key: String, stringValue: String) {
        self.key = key
        self.stringValue = stringValue
    }

    init(key: String, doubleValue: Double) {
        self.key = key
        self.doubleValue = doubleValue
    }

    init(key: String, boolValue: Bool) {
        self.key = key
        self.boolValue = boolValue
    }
}

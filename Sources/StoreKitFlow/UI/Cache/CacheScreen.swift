import SwiftUI

struct CacheScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore
    @State private var showClearAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if store.transactionHistory.isEmpty {
                    ContentUnavailableView(
                        "No Cached Transactions",
                        systemImage: "archivebox",
                        description: Text("Transactions will appear here after your first purchase or on initialize.")
                    )
                } else {
                    List(store.transactionHistory) { entry in
                        NavigationLink(destination: CacheTransactionDetailView(entry: entry)) {
                            CacheRow(entry: entry)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Cache")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear", role: .destructive) {
                        showClearAlert = true
                    }
                    .disabled(store.transactionHistory.isEmpty)
                }
            }
            .alert("Clear Transaction Cache?", isPresented: $showClearAlert) {
                Button("Clear", role: .destructive) {
                    store.clearTransactionHistory()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes the on-device transaction history. It does not affect your App Store purchases.")
            }
        }
    }
}

// MARK: - Row

struct CacheRow: View {
    let entry: CachedTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "archivebox.fill")
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.productID)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(entry.source.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(iconColor.opacity(0.15))
                        .foregroundStyle(iconColor)
                        .clipShape(Capsule())
                    Text(entry.purchaseDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if entry.deliveryCount > 0 {
                        Text("\(entry.deliveryCount)×")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12), in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var iconColor: Color {
        switch entry.source {
        case .purchase:   return .green
        case .renewal:    return .purple
        case .restore:    return .teal
        case .unfinished: return .orange
        }
    }
}

// MARK: - Detail

struct CacheTransactionDetailView: View {
    let entry: CachedTransaction

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()

    var body: some View {
        List {
            Section("Identity") {
                LabeledContent("Transaction ID", value: "#\(entry.id)")
                LabeledContent("Original Txn ID", value: "#\(entry.originalID)")
                LabeledContent("Product ID", value: entry.productID)
            }
            Section("Product") {
                LabeledContent("Type", value: entry.productType.rawValue.capitalized)
                LabeledContent("Environment", value: entry.environment)
                LabeledContent("Source", value: entry.source.rawValue.capitalized)
            }
            Section("Dates") {
                LabeledContent("Purchased", value: dateFormatter.string(from: entry.purchaseDate))
                LabeledContent("Expires", value: entry.expirationDate.map { dateFormatter.string(from: $0) } ?? "—")
                LabeledContent("Revoked", value: entry.revocationDate.map { dateFormatter.string(from: $0) } ?? "—")
                LabeledContent("Finished At", value: entry.finishedAt.map { dateFormatter.string(from: $0) } ?? "Not finished")
            }
            Section("Metadata") {
                LabeledContent("App Account Token", value: entry.appAccountToken.map { $0.uuidString } ?? "—")
            }
            Section {
                if entry.deliveryLog.isEmpty {
                    Text("No delivery events recorded.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.deliveryLog.reversed()) { event in
                        NavigationLink(destination: DeliveryEventDetailView(entry: entry, event: event, dateFormatter: dateFormatter)) {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(pathColor(event.path))
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.path.rawValue)
                                        .font(.system(.caption, design: .monospaced).weight(.medium))
                                    Text(dateFormatter.string(from: event.date))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Delivery Trail")
                    Spacer()
                    Text("\(entry.deliveryCount) event\(entry.deliveryCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Transaction #\(entry.id)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pathColor(_ path: TransactionDeliveryPath) -> Color {
        switch path {
        case .storePurchase:        return .green
        case .transactionUpdates:   return .blue
        case .transactionUnfinished: return .orange
        case .reconciliation:       return .purple
        }
    }
}

// MARK: - Delivery Event Detail

struct DeliveryEventDetailView: View {
    let entry: CachedTransaction
    let event: TransactionDeliveryEvent
    let dateFormatter: DateFormatter

    private var pathDescription: String {
        switch event.path {
        case .storePurchase:
            return "The user tapped Buy in your app's own UI and the purchase completed via store.purchase()."
        case .transactionUpdates:
            return "StoreKit delivered this transaction through Transaction.updates — typically a renewal, revocation, family sharing event, or Ask to Buy approval."
        case .transactionUnfinished:
            return "Found in Transaction.unfinished during app launch. This transaction was verified in a previous session but finish() was never called — likely due to a crash or background kill."
        case .reconciliation:
            return "Detected during a reconciliation pass of Transaction.currentEntitlements. This renewal was missed by the updates listener (e.g. the app was killed mid-renewal) and caught on next launch."
        }
    }

    var body: some View {
        List {
            Section("Identity") {
                LabeledContent("Transaction ID", value: "#\(entry.id)")
                LabeledContent("Original Txn ID", value: "#\(entry.originalID)")
                LabeledContent("Product ID", value: entry.productID)
            }
            Section("Product") {
                LabeledContent("Type", value: entry.productType.rawValue.capitalized)
                LabeledContent("Environment", value: entry.environment)
                LabeledContent("Source", value: entry.source.rawValue.capitalized)
            }
            Section("Dates") {
                LabeledContent("Purchased", value: dateFormatter.string(from: entry.purchaseDate))
                LabeledContent("Expires", value: entry.expirationDate.map { dateFormatter.string(from: $0) } ?? "—")
                LabeledContent("Revoked", value: entry.revocationDate.map { dateFormatter.string(from: $0) } ?? "—")
                LabeledContent("Finished At", value: entry.finishedAt.map { dateFormatter.string(from: $0) } ?? "Not finished")
            }
            Section("Metadata") {
                LabeledContent("App Account Token", value: entry.appAccountToken.map { $0.uuidString } ?? "—")
            }
            Section {
                LabeledContent("Code Path", value: event.path.rawValue)
                LabeledContent("Source", value: event.source.rawValue.capitalized)
                LabeledContent("Delivered At", value: dateFormatter.string(from: event.date))
                LabeledContent("Event ID", value: event.id.uuidString)
                Text(pathDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("This Delivery")
            }
        }
        .navigationTitle("Delivery Event")
        .navigationBarTitleDisplayMode(.inline)
    }
}

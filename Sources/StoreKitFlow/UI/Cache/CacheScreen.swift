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
        }
        .navigationTitle("Transaction #\(entry.id)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

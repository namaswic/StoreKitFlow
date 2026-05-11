import SwiftUI
import StoreKitFlow

enum LogFilter: Hashable {
    case productID(String)
    case transactionID(UInt64)
    case originalTransactionID(UInt64)

    var label: String {
        switch self {
        case .productID(let id): return id
        case .transactionID(let id): return "#\(id)"
        case .originalTransactionID(let id): return "Original #\(id)"
        }
    }
}

struct LogsScreen: View {
    @EnvironmentObject private var store: StoreKitFlowStore
    @State private var selectedCategory: StoreLogCategory? = nil
    @State private var selectedFilter: LogFilter? = nil

    private var extractedFilters: (productIDs: [String], transactionIDs: [UInt64], originalIDs: [UInt64]) {
        var productIDs = Set<String>()
        var transactionIDs = Set<UInt64>()
        var originalIDs = Set<UInt64>()

        for log in store.logs {
            switch log.event {
            case .transactionReceived(let pid, let tid, let oid),
                 .transactionVerified(let pid, let tid, let oid),
                 .transactionFinished(let pid, let tid, let oid),
                 .unfinishedTransactionFound(let pid, let tid, let oid):
                productIDs.insert(pid)
                transactionIDs.insert(tid)
                originalIDs.insert(oid)
            case .purchaseStarted(let pid),
                 .purchaseSucceeded(let pid),
                 .purchaseCancelled(let pid),
                 .purchasePending(let pid):
                productIDs.insert(pid)
            case .purchaseFailed(let pid, _):
                productIDs.insert(pid)
            case .transactionUnverified(let pid):
                productIDs.insert(pid)
            default:
                break
            }
        }

        return (
            productIDs.sorted(),
            transactionIDs.sorted(),
            originalIDs.sorted()
        )
    }

    private var filteredLogs: [StoreLog] {
        var logs = store.logs
        if let category = selectedCategory {
            logs = logs.filter { $0.event.category == category }
        }
        if let filter = selectedFilter {
            logs = logs.filter { log in
                switch (filter, log.event) {
                case (.productID(let pid), .transactionReceived(let p, _, _)),
                     (.productID(let pid), .transactionVerified(let p, _, _)),
                     (.productID(let pid), .transactionFinished(let p, _, _)),
                     (.productID(let pid), .unfinishedTransactionFound(let p, _, _)):
                    return p == pid
                case (.productID(let pid), .purchaseStarted(let p)),
                     (.productID(let pid), .purchaseSucceeded(let p)),
                     (.productID(let pid), .purchaseCancelled(let p)),
                     (.productID(let pid), .purchasePending(let p)):
                    return p == pid
                case (.productID(let pid), .purchaseFailed(let p, _)):
                    return p == pid
                case (.productID(let pid), .transactionUnverified(let p)):
                    return p == pid
                case (.transactionID(let tid), .transactionReceived(_, let t, _)),
                     (.transactionID(let tid), .transactionVerified(_, let t, _)),
                     (.transactionID(let tid), .transactionFinished(_, let t, _)),
                     (.transactionID(let tid), .unfinishedTransactionFound(_, let t, _)):
                    return t == tid
                case (.originalTransactionID(let oid), .transactionReceived(_, _, let o)),
                     (.originalTransactionID(let oid), .transactionVerified(_, _, let o)),
                     (.originalTransactionID(let oid), .transactionFinished(_, _, let o)),
                     (.originalTransactionID(let oid), .unfinishedTransactionFound(_, _, let o)):
                    return o == oid
                default:
                    return false
                }
            }
        }
        return logs
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredLogs.isEmpty {
                    ContentUnavailableView(
                        "No Logs",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text(store.logs.isEmpty
                            ? "Events will appear here as you interact with the store."
                            : "No logs match the selected filter.")
                    )
                } else {
                    List(filteredLogs) { log in
                        LogRow(log: log)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") { store.clearLogs() }
                        .disabled(store.logs.isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    filterMenu
                }
            }
            .safeAreaInset(edge: .top) {
                categoryFilterBar
            }
        }
    }

    private var filterMenu: some View {
        let filters = extractedFilters
        let hasFilters = !filters.productIDs.isEmpty || !filters.transactionIDs.isEmpty || !filters.originalIDs.isEmpty

        return Menu {
            if hasFilters {
                Button("All") { selectedFilter = nil }

                if !filters.productIDs.isEmpty {
                    Section("Product ID") {
                        ForEach(filters.productIDs, id: \.self) { pid in
                            Button {
                                selectedFilter = .productID(pid)
                            } label: {
                                if selectedFilter == .productID(pid) {
                                    Label(pid, systemImage: "checkmark")
                                } else {
                                    Text(pid)
                                }
                            }
                        }
                    }
                }

                if !filters.transactionIDs.isEmpty {
                    Section("Transaction ID") {
                        ForEach(filters.transactionIDs, id: \.self) { tid in
                            Button {
                                selectedFilter = .transactionID(tid)
                            } label: {
                                if selectedFilter == .transactionID(tid) {
                                    Label("#\(tid)", systemImage: "checkmark")
                                } else {
                                    Text("#\(tid)")
                                }
                            }
                        }
                    }
                }

                if !filters.originalIDs.isEmpty {
                    Section("Original Transaction ID") {
                        ForEach(filters.originalIDs, id: \.self) { oid in
                            Button {
                                selectedFilter = .originalTransactionID(oid)
                            } label: {
                                if selectedFilter == .originalTransactionID(oid) {
                                    Label("Original #\(oid)", systemImage: "checkmark")
                                } else {
                                    Text("Original #\(oid)")
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No filters available yet")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle\(selectedFilter != nil ? ".fill" : "")")
                if let filter = selectedFilter {
                    Text(filter.label)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(StoreLogCategory.allCases, id: \.self) { category in
                    FilterChip(title: category.rawValue, isSelected: selectedCategory == category) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }
}

#Preview {
    LogsScreen()
        .environmentObject(StoreKitFlowStore(
            productService: MockProductService(),
            entitlementService: MockEntitlementService(),
            transactionService: MockTransactionService()
        ))
}

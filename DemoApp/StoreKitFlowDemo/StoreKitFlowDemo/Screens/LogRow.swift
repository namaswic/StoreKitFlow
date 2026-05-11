import SwiftUI
import StoreKitFlow

struct LogRow: View {
    let log: StoreLog
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: log.event.icon)
                        .foregroundStyle(iconColor)
                        .frame(width: 20)
                        .font(.body)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.event.category.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(shortDescription)
                            .font(.subheadline)
                            .foregroundStyle(log.event.isError ? .red : .primary)
                            .multilineTextAlignment(.leading)
                        Text(log.timestamp.formatted(date: .omitted, time: .standard))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                    ForEach(log.event.details, id: \.label) { detail in
                        HStack(alignment: .top) {
                            Text(detail.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 110, alignment: .leading)
                            Text(detail.value)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(.leading, 30)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var shortDescription: String {
        switch log.event {
        case .fetchStarted:                 return "Fetching products…"
        case .fetchCompleted(let count):    return "Fetched \(count) product(s)"
        case .fetchFailed:                  return "Fetch failed"
        case .purchaseStarted:              return "Purchase started"
        case .purchaseSucceeded:            return "Purchase succeeded"
        case .purchaseCancelled:            return "Cancelled by user"
        case .purchasePending:              return "Pending approval"
        case .purchaseFailed:               return "Purchase failed"
        case .transactionReceived:          return "Transaction received"
        case .transactionVerified:          return "Transaction verified"
        case .transactionUnverified:        return "Transaction unverified"
        case .transactionFinished:          return "Transaction finished"
        case .unfinishedTransactionFound:   return "Unfinished transaction found"
        case .entitlementsLoaded:           return "Entitlements loaded"
        }
    }

    private var iconColor: Color {
        if log.event.isError { return .red }
        switch log.event.category {
        case .productService:   return .blue
        case .purchaseFlow:     return .green
        case .transactions:     return .purple
        case .entitlements:     return .orange
        }
    }
}

#Preview {
    List {
        LogRow(log: StoreLog(event: .fetchCompleted(count: 9)))
        LogRow(log: StoreLog(event: .purchaseSucceeded(productID: "com.storekitflow.demo.pro.monthly")))
        LogRow(log: StoreLog(event: .transactionVerified(productID: "com.storekitflow.demo.pro.monthly", transactionID: 12345, originalTransactionID: 12340)))
        LogRow(log: StoreLog(event: .fetchFailed(error: "Network connection lost")))
    }
}

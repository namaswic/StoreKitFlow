import SwiftUI
import StoreKit

struct SKDataBindingDemoScreen: View {
    var body: some View {
        List {
            StoreProductTaskSection()
            SubscriptionStatusTaskSection()
        }
        .listSectionSpacing(12)
        .navigationTitle("Data Binding")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - storeProductTask

private struct StoreProductTaskSection: View {
    @State private var product: Product?
    @State private var loadState: LoadState = .idle

    var body: some View {
        Section {
            switch loadState {
            case .idle:
                Text("Attach .storeProductTask to any view to declaratively load product metadata without manual async calls.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .loading:
                HStack {
                    ProgressView()
                    Text("Loading product…")
                        .foregroundStyle(.secondary)
                }
            case .loaded:
                if let product {
                    LabeledContent("Name", value: product.displayName)
                    LabeledContent("Price", value: product.displayPrice)
                    LabeledContent("Type", value: product.type.localizedDescription)
                }
            case .failed(let error):
                Label(error, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        } header: {
            Label("storeProductTask", systemImage: "bolt.fill")
        } footer: {
            InfoBox {
                InfoItem.api(".storeProductTask(for:)", "loads a single Product declaratively — no manual async calls")
                InfoItem.note("Action closure receives TaskState<Product>: .loading, .success, .failure")
                InfoItem.availability("iOS 17+")
            }
        }
        .storeProductTask(for: "com.storekitflow.demo.pro.monthly") { taskState in
            switch taskState {
            case .loading:
                loadState = .loading
            case .success(let p):
                product = p
                loadState = .loaded
            case .failure(let error):
                loadState = .failed(error.localizedDescription)
            @unknown default:
                break
            }
        }
    }
}

// MARK: - subscriptionStatusTask

private struct SubscriptionStatusTaskSection: View {
    @State private var statuses: [Product.SubscriptionInfo.Status] = []
    @State private var loadState: LoadState = .idle

    var body: some View {
        Section {
            switch loadState {
            case .idle:
                Text("Attach .subscriptionStatusTask to observe live subscription status changes for a group.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .loading:
                HStack {
                    ProgressView()
                    Text("Checking subscription status…")
                        .foregroundStyle(.secondary)
                }
            case .loaded:
                if statuses.isEmpty {
                    Label("No active subscriptions in this group", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(statuses.indices, id: \.self) { i in
                        let status = statuses[i]
                        LabeledContent("Status \(i + 1)", value: status.state.localizedDescription)
                    }
                }
            case .failed(let error):
                Label(error, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        } header: {
            Label("subscriptionStatusTask", systemImage: "antenna.radiowaves.left.and.right")
        } footer: {
            InfoBox {
                InfoItem.api(".subscriptionStatusTask(for:)", "observes live status for an entire subscription group")
                InfoItem.note("Called on launch and on every status change — renewal, expiry, cancellation")
                InfoItem.note("Returns [Product.SubscriptionInfo.Status], one per active subscription")
                InfoItem.availability("iOS 17+")
            }
        }
        .subscriptionStatusTask(for: "763D6759") { taskState in
            switch taskState {
            case .loading:
                loadState = .loading
            case .success(let s):
                statuses = s
                loadState = .loaded
            case .failure(let error):
                loadState = .failed(error.localizedDescription)
            @unknown default:
                break
            }
        }
    }
}

private enum LoadState {
    case idle, loading, loaded
    case failed(String)
}

#Preview {
    NavigationStack {
        SKDataBindingDemoScreen()
    }
}

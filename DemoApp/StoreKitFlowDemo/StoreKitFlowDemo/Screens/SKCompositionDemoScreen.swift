import SwiftUI
import StoreKit

struct SKCompositionDemoScreen: View {
    @State private var showStoreContentSheet = false

    var body: some View {
        List {
            if #available(iOS 18.0, *) {
                storeContentSection
            } else {
                Section {
                    ContentUnavailableView(
                        "Requires iOS 18",
                        systemImage: "exclamationmark.triangle",
                        description: Text("StoreContent and StoreContentBuilder require iOS 18 or later.")
                    )
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listSectionSpacing(12)
        .navigationTitle("Composition")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showStoreContentSheet) { storeContentSheet }
    }

    // MARK: - StoreContent + StoreContentBuilder

    @available(iOS 18.0, *)
    private var storeContentSection: some View {
        Section {
            Button { showStoreContentSheet = true } label: {
                Label("Preview StoreContent Layout", systemImage: "square.stack.3d.up.fill")
            }
        } header: {
            Label("StoreContent · StoreContentBuilder", systemImage: "square.stack.3d.up.fill")
        } footer: {
            InfoBox {
                InfoItem.api("StoreContent", "declarative descriptor for custom store layouts — defines what products and sections appear in a StoreView")
                InfoItem.api("@StoreContentBuilder", "result builder that lets you compose multiple StoreContent values using declarative block syntax")
                InfoItem.note("Use StoreContentBuilder to build a custom product listing by declaring which product IDs to show and how to group them.")
                InfoItem.availability("iOS 18+")
            }
        }
    }

    @ViewBuilder
    private var storeContentSheet: some View {
        if #available(iOS 18.0, *) {
            StoreView(ids: [
                "com.storekitflow.demo.coins10",
                "com.storekitflow.demo.removeads",
                "com.storekitflow.demo.themes",
                "com.storekitflow.demo.pass.30days"
            ]) { _ in 
                Image(systemName: "bag.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.indigo.gradient, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

#Preview {
    NavigationStack {
        SKCompositionDemoScreen()
    }
}

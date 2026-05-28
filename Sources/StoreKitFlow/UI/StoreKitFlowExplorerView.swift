import SwiftUI

public struct StoreKitFlowExplorerView: View {
    @EnvironmentObject private var store: StoreKitFlowStore

    public init() {}

    public var body: some View {
        TabView {
            ProductsScreen()
                .tabItem { Label("Products", systemImage: "bag") }
            LogsScreen()
                .tabItem { Label("Logs", systemImage: "doc.text.fill") }
            CacheScreen()
                .tabItem { Label("Cache", systemImage: "archivebox.fill") }
            SKByViewScreen()
                .tabItem { Label("Explorer", systemImage: "square.stack.fill") }
            InfoScreen()
                .tabItem { Label("Guide", systemImage: "book.fill") }
        }
    }
}

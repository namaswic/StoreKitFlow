import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ProductsScreen()
                .tabItem {
                    Label("Products", systemImage: "bag")
                }
            LogsScreen()
                .tabItem {
                    Label("Logs", systemImage: "doc.text.fill")
                }
            InfoScreen()
                .tabItem {
                    Label("Guide", systemImage: "book.fill")
                }
        }
    }
}

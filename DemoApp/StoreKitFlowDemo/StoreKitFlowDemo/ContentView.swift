import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ProductsScreen()
                .tabItem {
                    Label("Products", systemImage: "bag")
                }
            InfoScreen()
                .tabItem {
                    Label("Guide", systemImage: "book.fill")
                }
        }
    }
}

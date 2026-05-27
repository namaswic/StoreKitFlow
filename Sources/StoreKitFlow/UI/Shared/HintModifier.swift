import SwiftUI

extension View {
    /// Adds a secondary caption hint line below the view inside a List row.
    func hint(_ text: String) -> some View {
        self.modifier(HintModifier(text: text))
    }
}

private struct HintModifier: ViewModifier {
    let text: String

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            content
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

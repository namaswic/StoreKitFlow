import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .bold()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        FilterChip(title: "All", isSelected: true, action: {})
        FilterChip(title: "Purchase Flow", isSelected: false, action: {})
        FilterChip(title: "Transactions", isSelected: false, action: {})
    }
    .padding()
}

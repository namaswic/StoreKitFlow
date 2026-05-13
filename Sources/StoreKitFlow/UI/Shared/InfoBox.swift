import SwiftUI

struct InfoBox: View {
    let items: [InfoItem]

    init(@InfoItemBuilder _ items: () -> [InfoItem]) {
        self.items = items()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items.indices, id: \.self) { i in
                items[i].view
                if i < items.count - 1 {
                    Divider()
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - InfoItem

struct InfoItem {
    let view: AnyView

    static func api(_ name: String, _ description: String) -> InfoItem {
        InfoItem(view: AnyView(
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(.caption, design: .monospaced).weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.85), in: RoundedRectangle(cornerRadius: 5))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        ))
    }

    static func note(_ text: String) -> InfoItem {
        InfoItem(view: AnyView(
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        ))
    }

    static func availability(_ text: String) -> InfoItem {
        InfoItem(view: AnyView(
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            }
        ))
    }
}

// MARK: - Result Builder

@resultBuilder
struct InfoItemBuilder {
    static func buildBlock(_ items: InfoItem...) -> [InfoItem] { items }
}

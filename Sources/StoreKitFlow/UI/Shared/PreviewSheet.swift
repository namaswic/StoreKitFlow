import SwiftUI

struct PreviewSheetVariant {
    let label: String
    let modifiers: [String]
    let content: AnyView
}

struct PreviewSheet: View {
    let title: String
    let modifiers: [String]
    var variants: [PreviewSheetVariant]? = nil
    var showDismissButton: Bool = false
    let content: AnyView

    @Environment(\.dismiss) private var dismiss
    @State private var colorScheme: ColorScheme? = nil
    @State private var typeSize: DynamicTypeSize = .large
    @State private var showTypePicker = false
    @State private var selectedVariant: Int = 0
    @State private var showDrawer = false

    private var activeModifiers: [String] {
        if let variants, !variants.isEmpty {
            return variants[selectedVariant].modifiers
        }
        return modifiers
    }

    private var activeContent: AnyView {
        if let variants, !variants.isEmpty {
            return variants[selectedVariant].content
        }
        return content
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let variants, variants.count >= 2 {
                    variantPicker(variants)
                }
                activeContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .preferredColorScheme(colorScheme)
            .dynamicTypeSize(typeSize)
            .navigationTitle(title)
            .inlineNavigationTitle()
            .toolbar { toolbarItems }
            .safeAreaInset(edge: .bottom) { if showDrawer { modifierDrawer } }
        }
        .sheet(isPresented: $showTypePicker) { typeSizePicker }
    }

    private func variantPicker(_ variants: [PreviewSheetVariant]) -> some View {
        Picker("Variant", selection: $selectedVariant) {
            ForEach(variants.indices, id: \.self) { i in
                Text(variants[i].label).tag(i)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        if showDismissButton {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { withAnimation(.spring(duration: 0.3)) { showDrawer.toggle() } } label: {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .symbolVariant(showDrawer ? .fill : .none)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    colorScheme = colorScheme == .dark ? .light : .dark
                }
            } label: {
                Image(systemName: colorScheme == .dark ? "sun.max" : "moon")
                    .transition(.scale.combined(with: .opacity))
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showTypePicker = true } label: {
                Text("Aa")
                    .font(.caption.bold())
            }
        }
    }

    private var modifierDrawer: some View {
        VStack(spacing: 0) {
            Divider()
                .transition(.opacity)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Modifiers")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button { copyAll() } label: {
                        Label("Copy all", systemImage: "doc.on.doc.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(activeModifiers.indices, id: \.self) { i in
                            CodeLine(text: activeModifiers[i])
                            if i < activeModifiers.count - 1 {
                                Divider().padding(.vertical, 1)
                            }
                        }
                    }
                }
                .frame(maxHeight: 120)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
    }

    private var typeSizePicker: some View {
        NavigationStack {
            Picker("Dynamic Type Size", selection: $typeSize) {
                Text("Small").tag(DynamicTypeSize.small)
                Text("Medium").tag(DynamicTypeSize.medium)
                Text("Large (default)").tag(DynamicTypeSize.large)
                Text("XLarge").tag(DynamicTypeSize.xLarge)
                Text("XXLarge").tag(DynamicTypeSize.xxLarge)
                Text("XXXLarge").tag(DynamicTypeSize.xxxLarge)
                Text("Accessibility 1").tag(DynamicTypeSize.accessibility1)
                Text("Accessibility 2").tag(DynamicTypeSize.accessibility2)
                Text("Accessibility 3").tag(DynamicTypeSize.accessibility3)
            }
            .pickerStyle(.wheel)
            .navigationTitle("Dynamic Type")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showTypePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func copyAll() {
        let text = activeModifiers.joined(separator: "\n")
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

extension PreviewSheet {
    init(
        title: String,
        modifiers: [String],
        variants: [PreviewSheetVariant]? = nil,
        showDismissButton: Bool = false,
        @ViewBuilder content: () -> some View
    ) {
        self.title = title
        self.modifiers = modifiers
        self.variants = variants
        self.showDismissButton = showDismissButton
        self.content = AnyView(content())
    }
}

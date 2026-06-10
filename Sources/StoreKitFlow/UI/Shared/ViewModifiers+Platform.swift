import SwiftUI

extension View {
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func listSectionSpacingCompact() -> some View {
        #if os(iOS)
        self.listSectionSpacing(12)
        #else
        self
        #endif
    }
}

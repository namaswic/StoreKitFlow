import SwiftUI

struct ProductFamilySharingView: View {
    let familyShareable: Bool

    var body: some View {
        HStack {
            Label("Family Sharing", systemImage: "person.3.fill")
                .font(.headline)
            Spacer()
            Text(familyShareable ? "Enabled" : "Not Available")
                .font(.subheadline)
                .foregroundStyle(familyShareable ? .green : .secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

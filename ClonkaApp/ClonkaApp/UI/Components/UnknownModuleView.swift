import SwiftUI

struct UnknownModuleView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("This module is not yet available.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Unknown Module")
    }
}

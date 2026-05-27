import SwiftUI

struct UnknownModuleView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(L10n.UnknownModule_Description.key)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .navigationTitle(L10n.UnknownModule_Title.key)
    }
}

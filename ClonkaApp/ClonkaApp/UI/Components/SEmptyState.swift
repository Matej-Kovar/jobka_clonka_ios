import SwiftUI

struct SEmptyState: View {
    var icon: String = "tray"
    var message: String = L10n.NoItemsFound.string

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundStyle(.secondary.opacity(0.6))
                .symbolEffect(.pulse.wholeSymbol, options: .nonRepeating)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

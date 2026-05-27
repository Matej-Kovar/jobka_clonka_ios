import SwiftUI

struct MaintenanceView: View {
    var body: some View {
        VStack {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 60))
            Text(L10n.MaintenanceMode_Title.key)
                .font(.title)
            Text(L10n.MaintenanceMode_Description.key)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

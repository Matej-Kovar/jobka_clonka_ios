import SwiftUI

struct MaintenanceView: View {
    var body: some View {
        VStack {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 60))
            Text("Maintenance Mode")
                .font(.title)
            Text("The app is currently under maintenance. Please try again later.")
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

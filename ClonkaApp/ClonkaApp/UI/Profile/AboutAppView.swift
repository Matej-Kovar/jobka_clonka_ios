import SwiftUI

struct AboutAppView: View {
    @EnvironmentObject var appState: AppState
    @State private var versionTapCount = 0
    @State private var showDeveloperPrompt = false
    @State private var developerPassword = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundStyle(JobkaTheme.primary)
            Text("Clonka")
                .font(.largeTitle.bold())
            Text("Employee Portal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .onTapGesture {
                    versionTapCount += 1
                    if versionTapCount >= 7 {
                        versionTapCount = 0
                        if appState.isDeveloperMode {
                            appState.isDeveloperMode = false
                        } else {
                            showDeveloperPrompt = true
                        }
                    }
                }
            Text("© 2024 Skeleton s.r.o.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if appState.isDeveloperMode {
                Label("Developer Mode Active", systemImage: "wrench.and.screwdriver")
                    .font(.caption2)
                    .foregroundStyle(JobkaTheme.primary)
            }
        }
        .navigationTitle("About")
        .alert("Developer Mode", isPresented: $showDeveloperPrompt) {
            TextField("Password", text: $developerPassword)
            Button("Cancel", role: .cancel) { developerPassword = "" }
            Button("Activate") {
                if developerPassword.lowercased() == "skeleton" {
                    appState.isDeveloperMode = true
                    AppLogger.auth.info("🔓 Developer mode activated from About")
                }
                developerPassword = ""
            }
        } message: {
            Text("Enter developer password")
        }
    }
}

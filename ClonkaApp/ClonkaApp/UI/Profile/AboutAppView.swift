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
            Text(L10n.App_Name.key)
                .font(.largeTitle.bold())
            Text(L10n.App_Description.key)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(L10n.AboutApp_Version.key)
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
            Text(L10n.AboutApp_Developer.key)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if appState.isDeveloperMode {
                Label(L10n.AboutApp_DeveleperMode.key, systemImage: "wrench.and.screwdriver")
                    .font(.caption2)
                    .foregroundStyle(JobkaTheme.primary)
            }
        }
        .navigationTitle(L10n.AboutApp_Title.key)
        .alert(L10n.DeveloperMode.key, isPresented: $showDeveloperPrompt) {
            TextField(L10n.Auth_Password.key, text: $developerPassword)
            Button(L10n.Auth_Password.key, role: .cancel) { developerPassword = "" }
            Button(L10n.Activate.key) {
                if developerPassword.lowercased() == "skeleton" {
                    appState.isDeveloperMode = true
                    AppLogger.auth.info("🔓 Developer mode activated from About")
                }
                developerPassword = ""
            }
        } message: {
            Text(L10n.Auth_EnterDeveloperPassword.key)
        }
    }
}

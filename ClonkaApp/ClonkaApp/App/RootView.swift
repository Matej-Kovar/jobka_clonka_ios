import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        Group {
            if appState.isMaintenanceMode {
                MaintenanceView()
            } else if sessionManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(appState.colorSchemeOverride)
        .task {
            ConfigManager.shared.loadConfig()
            AppLogger.lifecycle.info(
                "🚀 App started, env=\(ConfigManager.shared.currentEnvironment.rawValue)")
            await autoLoginIfNeeded()
        }
    }

    /// Auto-login using launch arguments: -personalNumber 1 -accessCode <qr-guid>
    private func autoLoginIfNeeded() async {
        let args = ProcessInfo.processInfo.arguments
        guard let pnIndex = args.firstIndex(of: "-personalNumber"),
              pnIndex + 1 < args.count,
              let acIndex = args.firstIndex(of: "-accessCode"),
              acIndex + 1 < args.count
        else { return }

        let pn = args[pnIndex + 1]
        let ac = args[acIndex + 1]
        AppLogger.auth.info("🤖 Auto-login: pn=\(pn)")

        let result = await AuthAPIService.login(personalNumber: pn, accessCode: ac)
        switch result {
        case .success(let response):
            guard response.ID_Login != nil else {
                AppLogger.auth.error("❌ Auto-login: no ID_Login in response")
                return
            }
            let env = ConfigManager.shared.currentEnvironment.rawValue
            await sessionManager.login(response: response, personalNumber: pn, accessCode: ac, environment: env)
            AppLogger.auth.info("✅ Auto-login success: \(response.DisplayName ?? "?")")
        case .failure(let error):
            AppLogger.auth.error("❌ Auto-login failed: \(error.localizedDescription)")
        }
    }
}

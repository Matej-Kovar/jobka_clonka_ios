import SwiftUI

@main
struct ClonkaApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var sessionManager = SessionManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Color("AccentColor"))
                .environmentObject(appState)
                .environmentObject(sessionManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    /// Handle deep links: clonka://navigate/SurveyList/29780
    private func handleDeepLink(_ url: URL) {
        AppLogger.navigation.info("🔗 Deep link: \(url.absoluteString)")
        guard url.scheme == "clonka", url.host == "navigate" else { return }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard let routeStr = parts.first,
              let route = MenuRoute(rawValue: routeStr) else { return }
        let moduleId = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
        let title = parts.count > 2 ? parts[2] : routeStr
        appState.pendingNavigation = ModuleDestination(route: route, moduleId: moduleId, title: title)
    }
}

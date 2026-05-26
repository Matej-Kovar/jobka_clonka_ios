import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isMaintenanceMode = false
    @Published var isDeveloperMode = false
    @Published var colorSchemeOverride: ColorScheme?
    @Published var pendingNavigation: ModuleDestination?
    @Published var pendingChatNavigation: ChatDestination?

    static let shared = AppState()
}

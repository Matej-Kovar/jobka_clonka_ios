import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var personalNumber = ""
    @Published var accessCode = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showQRScanner = false
    @Published var showManualEntry = true
    @Published var versionTapCount = 0
    @Published var showDeveloperPrompt = false
    @Published var developerPassword = ""
    @Published var showSettings = false
    @Published var selectedEnvironment: ConfigManager.AppEnvironment = ConfigManager.shared.currentEnvironment

    private let sessionManager = SessionManager.shared

    var savedProfiles: [SessionManager.SavedProfile] {
        sessionManager.savedProfiles
    }

    func login() async {
        guard !personalNumber.isEmpty else {
            errorMessage = "Please enter your personal number"
            return
        }
        guard !accessCode.isEmpty else {
            errorMessage = "Please enter your access code"
            return
        }

        isLoading = true
        errorMessage = nil

        AppLogger.auth.info("🔑 Login attempt: pn=\(self.personalNumber)")

        let result = await AuthAPIService.login(
            personalNumber: personalNumber,
            accessCode: accessCode
        )

        switch result {
        case .success(let response):
            if let validationMessages = response.ValidationMessages, !validationMessages.isEmpty {
                let msgs = validationMessages.compactMap { $0.message ?? $0.code }
                errorMessage = msgs.joined(separator: "\n")
                AppLogger.auth.error("❌ Login validation errors: \(msgs)")
                isLoading = false
                return
            }

            guard response.ID_Login != nil else {
                errorMessage = "Login failed — no session token received"
                AppLogger.auth.error("❌ Login response missing ID_Login")
                isLoading = false
                return
            }

            let env = ConfigManager.shared.currentEnvironment.rawValue
            await sessionManager.login(
                response: response,
                personalNumber: personalNumber,
                accessCode: accessCode,
                environment: env
            )
            AppLogger.auth.info(
                "✅ Login flow complete, authenticated=\(self.sessionManager.isAuthenticated)")

        case .failure(let error):
            errorMessage = error.localizedDescription
            AppLogger.auth.error("❌ Login failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    func loginWithQR(code: String) {
        accessCode = code
        AppLogger.auth.info("📷 QR code scanned: \(AppLogger.redact(code))")
    }

    func loginWithSavedProfile(_ profile: SessionManager.SavedProfile) async {
        personalNumber = profile.personalNumber
        if let code = profile.accessCode {
            accessCode = code
            let env: ConfigManager.AppEnvironment =
                profile.environment == "Production" ? .production : .test
            ConfigManager.shared.switchEnvironment(env)
            await login()
        } else {
            AppLogger.auth.info(
                "📋 Selected saved profile \(profile.personalNumber) — needs access code")
        }
    }

    func deleteProfile(_ profile: SessionManager.SavedProfile) {
        sessionManager.deleteProfile(profile)
    }

    func handleVersionTap() {
        versionTapCount += 1
        if versionTapCount >= 7 {
            if AppState.shared.isDeveloperMode {
                // Already in dev mode — go straight to settings
                showSettings = true
            } else {
                showDeveloperPrompt = true
            }
            versionTapCount = 0
        }
    }

    func activateDeveloperMode() {
        if developerPassword.lowercased() == "skeleton" {
            AppState.shared.isDeveloperMode = true
            AppLogger.auth.info("🔓 Developer mode activated")
            // Open settings immediately after activation
            showSettings = true
        }
        showDeveloperPrompt = false
        developerPassword = ""
    }
}

import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var isAuthenticated = false
    @Published var currentProfile: UserProfile?
    @Published var savedProfiles: [SavedProfile] = []

    private let profilesKey = "savedProfiles"

    struct UserProfile {
        let idLogin: String
        let displayName: String
        let personalNumber: String
        let employeeId: Int?
        let initials: String?
        let color: String?
        let documentId: Int?
        let documentHash: String?
        let languages: [LanguageItem]
        let isTester: Bool
        let email: String?
        let phone: String?
        let languageId: String?
    }

    struct SavedProfile: Codable, Identifiable {
        let id: String
        let personalNumber: String
        let displayName: String
        let accessCode: String?
        let environment: String
        let lastUsed: Date
        let initials: String?
        let color: String?

        var environmentBadge: String { environment }
    }

    init() {
        loadSavedProfiles()
    }

    func login(
        response: LoginResponse, personalNumber: String,
        accessCode: String?, environment: String
    ) async {
        guard let idLogin = response.ID_Login else {
            AppLogger.auth.error("Login response missing ID_Login")
            return
        }

        AppLogger.auth.info(
            "✅ Login successful: user=\(response.DisplayName ?? "unknown"), pn=\(personalNumber)"
        )

        await APIClient.shared.setIdLogin(idLogin)

        currentProfile = UserProfile(
            idLogin: idLogin,
            displayName: response.DisplayName ?? "",
            personalNumber: personalNumber,
            employeeId: response.ID_Employee,
            initials: response.Initials,
            color: response.Color,
            documentId: response.ID_Document,
            documentHash: response.DocumentHash,
            languages: response.Languages ?? [],
            isTester: response.IsTester ?? false,
            email: response.Email,
            phone: response.Phone,
            languageId: response.ID_Language
        )

        isAuthenticated = true

        saveProfile(
            personalNumber: personalNumber,
            displayName: response.DisplayName ?? "",
            accessCode: accessCode,
            environment: environment,
            initials: response.Initials,
            color: response.Color
        )
    }

    func logout() async {
        AppLogger.auth.info("🚪 Logging out...")
        await APIClient.shared.setIdLogin(nil)
        currentProfile = nil
        isAuthenticated = false
    }

    func getIdLogin() -> String? {
        return currentProfile?.idLogin
    }

    // MARK: - Profile Management

    private func saveProfile(
        personalNumber: String, displayName: String,
        accessCode: String?, environment: String,
        initials: String?, color: String?
    ) {
        savedProfiles.removeAll {
            $0.personalNumber == personalNumber && $0.environment == environment
        }

        let profile = SavedProfile(
            id: UUID().uuidString,
            personalNumber: personalNumber,
            displayName: displayName,
            accessCode: accessCode,
            environment: environment,
            lastUsed: Date(),
            initials: initials,
            color: color
        )
        savedProfiles.insert(profile, at: 0)
        persistProfiles()
    }

    func deleteProfile(_ profile: SavedProfile) {
        savedProfiles.removeAll { $0.id == profile.id }
        persistProfiles()
    }

    private func persistProfiles() {
        if let data = try? JSONEncoder().encode(savedProfiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }

    private func loadSavedProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
            let profiles = try? JSONDecoder().decode(
                [SavedProfile].self, from: data)
        {
            savedProfiles = profiles.sorted { $0.lastUsed > $1.lastUsed }
        }
    }
}

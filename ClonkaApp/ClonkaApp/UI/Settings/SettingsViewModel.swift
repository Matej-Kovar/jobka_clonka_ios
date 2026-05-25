import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedLanguage: String = ""
    @Published var languages: [LanguageItem] = []
    @Published var isSaving = false

    func loadFromSession(_ session: SessionManager) {
        languages = session.currentProfile?.languages ?? []
        selectedLanguage = session.currentProfile?.languageId ?? ""
    }

    func changeLanguage(code: String) async {
        isSaving = true
        _ = await EmployeeAPIService.editLanguage(code: code)
        selectedLanguage = code
        isSaving = false
    }
}

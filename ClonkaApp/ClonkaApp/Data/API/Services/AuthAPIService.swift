import Foundation

struct AuthAPIService {
    static func login(personalNumber: String, accessCode: String) async -> AppResult<LoginResponse> {
        AppLogger.auth.info("🔑 Attempting login: pn=\(personalNumber)")

        let queryItems = [
            URLQueryItem(name: "PersonalNumber", value: personalNumber),
            URLQueryItem(name: "Code", value: accessCode),
            URLQueryItem(name: "Browser", value: "ClonkaSwift/1.0 iOS"),
            URLQueryItem(
                name: "Lang",
                value: Locale.current.language.languageCode?.identifier ?? "en"),
        ]

        return await APIClient.shared.wsGet(
            path: "/api/Employee/Login",
            queryItems: queryItems,
            responseType: LoginResponse.self
        )
    }

    static func checkMaintenanceMode(idLogin: String) async -> AppResult<EmptyResponse> {
        AppLogger.auth.info("🔧 Checking maintenance mode")
        let queryItems = [URLQueryItem(name: "ID_Login", value: idLogin)]
        return await APIClient.shared.wsGet(
            path: "/api/Company/CheckState",
            queryItems: queryItems,
            responseType: EmptyResponse.self
        )
    }

    static func editLanguage(idLogin: String, code: String) async -> AppResult<EmptyResponse> {
        struct EditLangBody: Encodable {
            let ID_Login: String
            let Code: String
        }
        return await APIClient.shared.wsPost(
            path: "/api/Employee/EditLanguage",
            body: EditLangBody(ID_Login: idLogin, Code: code),
            responseType: EmptyResponse.self
        )
    }
}

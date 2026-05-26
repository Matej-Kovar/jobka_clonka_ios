import Foundation

struct EmployeeAPIService {
    static func fetchProfile() async -> AppResult<EmployeeProfile> {
        AppLogger.api.info("👤 Fetching employee profile")
        return await APIClient.shared.clientGet(
            path: "/client/v1/employee",
            queryItems: [],
            responseType: EmployeeProfile.self
        )
    }

    static func fetchSettings() async -> AppResult<EmployeeSettings> {
        AppLogger.api.info("⚙️ Fetching employee settings")
        return await APIClient.shared.clientGet(
            path: "/client/v1/employee/settings",
            queryItems: [],
            responseType: EmployeeSettings.self
        )
    }

    static func deletePhoto() async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.wsPost(
            path: "/api/UserPhoto/DelUserLogin",
            body: PostReadRequest(ID_Login: idLogin),
            responseType: EmptyResponse.self
        )
    }

    static func editLanguage(code: String) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        struct EditLangBody: Encodable { let ID_Login: String; let Code: String }
        return await APIClient.shared.wsPost(
            path: "/api/Employee/EditLanguage",
            body: EditLangBody(ID_Login: idLogin, Code: code),
            responseType: EmptyResponse.self
        )
    }
}

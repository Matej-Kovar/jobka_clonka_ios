import Foundation

struct TrustBoxAPIService {
    static func submit(body: String, email: String?, moduleId: Int) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        AppLogger.api.info("🔒 Submitting trust box for module=\(moduleId)")
        return await APIClient.shared.wsPost(
            path: "/api/TrustBox/New",
            body: TrustBoxRequest(ID_Login: idLogin, Body: body, Email: email, ID_Module: moduleId),
            responseType: EmptyResponse.self
        )
    }
}

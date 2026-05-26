import Foundation

struct LicensePlateAPIService {
    static func processImage(licensePlate: String) async -> AppResult<LicensePlateResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        struct RequestBody: Encodable { let ID_Login: String; let LicensePlate: String }
        AppLogger.api.info("🚗 Processing license plate")
        return await APIClient.shared.wsPost(
            path: "/api/LicensePlate/ProcessImage",
            body: RequestBody(ID_Login: idLogin, LicensePlate: licensePlate),
            responseType: LicensePlateResponse.self
        )
    }
}

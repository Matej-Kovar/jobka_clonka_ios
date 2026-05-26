import Foundation

struct TelevisionAPIService {
    static func checkChanged(companyMenuItemId: Int) async -> AppResult<TelevisionChangeResponse> {
        AppLogger.api.info("📺 Checking television change for menuItem=\(companyMenuItemId)")
        return await APIClient.shared.wsGet(
            path: "/api/Television/DetailIsChanged",
            queryItems: [URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))],
            responseType: TelevisionChangeResponse.self
        )
    }

    static func fetchDetail(companyMenuItemId: Int) async -> AppResult<TelevisionDetail> {
        AppLogger.api.info("📺 Fetching television detail for menuItem=\(companyMenuItemId)")
        return await APIClient.shared.wsGet(
            path: "/api/Television/Detail",
            queryItems: [URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))],
            responseType: TelevisionDetail.self
        )
    }
}

import Foundation

struct CustomPageAPIService {
    static func fetchPages(companyMenuItemId: Int) async -> AppResult<[CustomPage]> {
        AppLogger.api.info("📄 Fetching custom pages for menuItem=\(companyMenuItemId)")
        return await APIClient.shared.wsGet(
            path: "/api/CustomPage/All",
            queryItems: [URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))],
            responseType: [CustomPage].self
        )
    }
}

import Foundation

struct ContactAPIService {
    static func fetchContacts(companyMenuItemId: Int) async -> AppResult<ContactsResponse> {
        AppLogger.api.info("👥 Fetching contacts for menuItem=\(companyMenuItemId)")
        return await APIClient.shared.wsGet(
            path: "/api/Contact/All",
            queryItems: [URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))],
            responseType: ContactsResponse.self
        )
    }
}

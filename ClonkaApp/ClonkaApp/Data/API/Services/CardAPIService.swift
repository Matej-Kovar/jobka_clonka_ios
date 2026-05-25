import Foundation

struct CardAPIService {
    static func fetchCard(companyMenuItemId: Int) async -> AppResult<CardInfo> {
        AppLogger.api.info("💳 Fetching card for menuItem=\(companyMenuItemId)")
        return await APIClient.shared.wsGet(
            path: "/api/Card/ActualCard",
            queryItems: [URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))],
            responseType: CardInfo.self
        )
    }
}

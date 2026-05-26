import Foundation

struct DataListAPIService {
    static func fetchList(companyMenuItemId: Int, search: String? = nil, top: Int = 20, offset: Int = 0) async -> AppResult<DataListResponse> {
        AppLogger.api.info("📊 Fetching data list for menuItem=\(companyMenuItemId)")
        var params = [
            URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId)),
            URLQueryItem(name: "Top", value: String(top)),
            URLQueryItem(name: "Offset", value: String(offset))
        ]
        if let search, !search.isEmpty {
            params.append(URLQueryItem(name: "Search", value: search))
        }
        return await APIClient.shared.wsGet(
            path: "/api/v2/Data/AllCompanyMenuItem",
            queryItems: params,
            responseType: DataListResponse.self
        )
    }

    static func fetchDetail(moduleId: Int, dataId: String) async -> AppResult<DataDetailResponse> {
        AppLogger.api.info("📊 Fetching detail moduleId=\(moduleId) dataId=\(dataId)")
        return await APIClient.shared.wsGet(
            path: "/api/v2/Data/DetailCompanyMenuItem",
            queryItems: [
                URLQueryItem(name: "ID_CompanyMenuItem", value: String(moduleId)),
                URLQueryItem(name: "ID_Data", value: dataId)
            ],
            responseType: DataDetailResponse.self
        )
    }
}

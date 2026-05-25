import Foundation

struct CanteenAPIService {
    static func fetchCanteens(companyMenuItemId: Int) async -> AppResult<[CanteenItem]> {
        AppLogger.api.info("🍽 Fetching canteens for menuItem=\(companyMenuItemId)")
        return await APIClient.shared.wsGet(
            path: "/api/Canteen/All",
            queryItems: [URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))],
            responseType: [CanteenItem].self
        )
    }

    static func login(password: String, companyMenuItemId: Int?) async -> AppResult<CanteenLoginResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.wsPost(
            path: "/api/Canteen/Login",
            body: CanteenLoginRequest(ID_Login: idLogin, Password: password, ID_CompanyMenuItem: companyMenuItemId),
            responseType: CanteenLoginResponse.self
        )
    }

    static func fetchMenu(canteenId: Int, day: String, externalLogin: String?, externalPersonId: String?) async -> AppResult<[CanteenSlot]> {
        var queryItems = [
            URLQueryItem(name: "ID_Canteen", value: String(canteenId)),
            URLQueryItem(name: "Day", value: day),
        ]
        if let el = externalLogin { queryItems.append(URLQueryItem(name: "ExternalLogin", value: el)) }
        if let ep = externalPersonId { queryItems.append(URLQueryItem(name: "ExternalPersonId", value: ep)) }
        return await APIClient.shared.wsGet(
            path: "/api/Canteen/CarteChoiceAll",
            queryItems: queryItems,
            responseType: [CanteenSlot].self
        )
    }

    static func placeOrder(order: CanteenOrderRequest) async -> AppResult<EmptyResponse> {
        return await APIClient.shared.wsPost(
            path: "/api/Canteen/OrderNew",
            body: order,
            responseType: EmptyResponse.self
        )
    }
}

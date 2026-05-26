import Foundation

struct MessageAPIService {
    static func fetchConversations(companyMenuItemId: Int) async -> AppResult<[ConversationListItem]> {
        AppLogger.api.info("💬 Fetching conversations for menuItem=\(companyMenuItemId)")
        return await APIClient.shared.wsGet(
            path: "/api/EmployeeMessage/All",
            queryItems: [URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))],
            responseType: [ConversationListItem].self
        )
    }

    static func fetchDMHistory(employeeId: Int, companyMenuItemId: Int) async -> AppResult<[ChatMessage]> {
        AppLogger.api.info("💬 Fetching DM history employee=\(employeeId)")
        return await APIClient.shared.wsGet(
            path: "/api/EmployeeMessage/AllEmployee",
            queryItems: [
                URLQueryItem(name: "ID_Employee", value: String(employeeId)),
                URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))
            ],
            responseType: [ChatMessage].self
        )
    }

    static func fetchGroupHistory(groupId: Int, companyMenuItemId: Int) async -> AppResult<[ChatMessage]> {
        AppLogger.api.info("💬 Fetching group history group=\(groupId)")
        return await APIClient.shared.wsGet(
            path: "/api/EmployeeMessage/AllMessageGroup",
            queryItems: [
                URLQueryItem(name: "ID_MessageGroup", value: String(groupId)),
                URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))
            ],
            responseType: [ChatMessage].self
        )
    }

    static func fetchAvailableEmployees(companyMenuItemId: Int?) async -> AppResult<[ChatEmployee]> {
        AppLogger.api.info("💬 Fetching available employees for chat")
        var queryItems: [URLQueryItem] = []
        if let menuItemId = companyMenuItemId {
            queryItems.append(URLQueryItem(name: "ID_CompanyMenuItem", value: String(menuItemId)))
        }
        return await APIClient.shared.wsGet(
            path: "/api/Employee/AllCompanyChat",
            queryItems: queryItems,
            responseType: [ChatEmployee].self
        )
    }

    static func sendMessage(employeeId: Int?, groupId: Int?, message: String, menuItemId: Int?) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.wsPost(
            path: "/api/EmployeeMessage/New",
            body: SendMessageRequest(
                ID_Login: idLogin,
                ID_EmployeeReceiver: employeeId,
                ID_MessageGroup: groupId,
                Message: message,
                ID_CompanyMenuItem: menuItemId
            ),
            responseType: EmptyResponse.self
        )
    }

    static func createGroup(displayName: String, description: String?, menuItemId: Int?) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.wsPost(
            path: "/api/MessageGroup/New",
            body: MessageGroupCreateRequest(
                ID_Login: idLogin,
                DisplayName: displayName,
                Description: description,
                ID_CompanyMenuItem: menuItemId
            ),
            responseType: EmptyResponse.self
        )
    }
}

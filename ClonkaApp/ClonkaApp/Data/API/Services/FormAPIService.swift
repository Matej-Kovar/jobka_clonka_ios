import Foundation

struct FormAPIService {
    private static var fieldsCache: [String: [FormFieldDefinition]] = [:]

    static func cachedFields(companyMenuItemId: Int, dataId: String? = nil) -> [FormFieldDefinition]? {
        fieldsCache[cacheKey(companyMenuItemId: companyMenuItemId, dataId: dataId)]
    }

    static func prefetchFields(companyMenuItemId: Int, dataId: String? = nil) async {
        let key = cacheKey(companyMenuItemId: companyMenuItemId, dataId: dataId)
        guard fieldsCache[key] == nil else { return }
        let result = await fetchFields(companyMenuItemId: companyMenuItemId, dataId: dataId)
        if case .success(let fields) = result {
            fieldsCache[key] = fields
        }
    }

    static func fetchFields(companyMenuItemId: Int, dataId: String? = nil) async -> AppResult<[FormFieldDefinition]> {
        AppLogger.api.info("📝 Fetching form fields for menuItem=\(companyMenuItemId)")
        let key = cacheKey(companyMenuItemId: companyMenuItemId, dataId: dataId)
        var queryItems = [URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))]
        if let dataId, !dataId.isEmpty {
            queryItems.append(URLQueryItem(name: "ID_Data", value: dataId))
        }
        let result = await APIClient.shared.wsGet(
            path: "/api/v2/FormItem/AllForm",
            queryItems: queryItems,
            responseType: [FormFieldDefinition].self
        )
        if case .success(let fields) = result {
            fieldsCache[key] = fields
        }
        return result
    }

    static func submitForm(companyFormId: Int, dataItems: [FormDataItemValue], dataId: String? = nil) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.wsPost(
            path: "/api/v2/Data/NewDataItems",
            body: FormSubmitRequest(ID_Login: idLogin, ID_CompanyForm: companyFormId, ID_Data: dataId, DataItems: dataItems),
            responseType: EmptyResponse.self
        )
    }

    private static func cacheKey(companyMenuItemId: Int, dataId: String?) -> String {
        "\(companyMenuItemId)|\(dataId ?? "")"
    }
}

struct FormSubmitRequest: Encodable {
    let ID_Login: String
    let ID_CompanyForm: Int
    let ID_Data: String?
    let DataItems: [FormDataItemValue]
}

struct FormDataItemValue: Encodable {
    let ID_FormItem: Int
    let Value: String
}

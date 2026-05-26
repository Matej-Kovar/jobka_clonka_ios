import Foundation

struct FormAPIService {
    static func fetchFields(companyMenuItemId: Int) async -> AppResult<[FormFieldDefinition]> {
        AppLogger.api.info("📝 Fetching form fields for menuItem=\(companyMenuItemId)")
        return await APIClient.shared.wsGet(
            path: "/api/v2/FormItem/AllForm",
            queryItems: [URLQueryItem(name: "ID_CompanyMenuItem", value: String(companyMenuItemId))],
            responseType: [FormFieldDefinition].self
        )
    }

    static func submitForm(companyFormId: Int, dataItems: [FormDataItemValue], dataId: String? = nil) async -> AppResult<EmptyResponse> {
        let idLogin = await APIClient.shared.idLogin ?? ""
        return await APIClient.shared.wsPost(
            path: "/api/v2/Data/NewDataItems",
            body: FormSubmitRequest(ID_Login: idLogin, ID_CompanyForm: companyFormId, ID_Data: dataId, DataItems: dataItems),
            responseType: EmptyResponse.self
        )
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

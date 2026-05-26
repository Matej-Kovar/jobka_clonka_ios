import Foundation

// MARK: - Stream Posts

struct StreamPostItem: Decodable, Identifiable {
    let ID: Int?
    let DisplayName: String?
    let DateCreated: Date?
    let Message: String?
    let MessageHtml: String?
    let Author: String?
    let NumberOfComments: Int?
    let ID_Document: Int?
    let DocumentHash: String?

    var id: Int { self.ID ?? 0 }
}

struct StreamPostDetail: Decodable {
    let ID: Int?
    let DisplayName: String?
    let DateCreated: Date?
    let Message: String?
    let MessageHtml: String?
    let Author: String?
    let ID_Document: Int?
    let DocumentHash: String?
    let DocumentUrl: String?
    let Comments: [StreamComment]?
}

struct StreamComment: Decodable, Identifiable {
    let ID: Int
    let Author: String?
    let DateCreated: Date?
    let Comment: String?
    let IsReply: Bool?
    let Level: Int?
    let ID_StreamPostParent: Int?
    let ReplyComments: [StreamComment]?

    var id: Int { self.ID }
}

struct StreamPostNewRequest: Encodable {
    let ID_Login: String
    let DisplayName: String?
    let Message: String?
    let ID_Module: Int?
}

struct StreamCommentNewRequest: Encodable {
    let ID_Login: String
    let ID_StreamPost: Int
    let Comment: String
    let ID_StreamPostParent: Int?
}

// MARK: - Card

struct CardInfo: Decodable {
    let CardNumber: String?
    let Email: String?
    let PrimaryColor: String?
    let IsRegistered: Bool?
}

// MARK: - Trust Box

struct TrustBoxRequest: Encodable {
    let ID_Login: String
    let Body: String
    let Email: String?
    let ID_Module: Int?
}

// MARK: - Custom Pages

struct CustomPage: Decodable, Identifiable {
    let ID: Int?
    let DisplayName: String?
    let Url: String?
    let HtmlContent: String?
    let IsZoomable: Bool?

    var id: Int { self.ID ?? 0 }
    var hasUrl: Bool { Url != nil && !(Url?.isEmpty ?? true) }
    var hasHtml: Bool { HtmlContent != nil && !(HtmlContent?.isEmpty ?? true) }
}

// MARK: - Television

struct TelevisionChangeResponse: Decodable {
    let IsChanged: Bool?
}

struct TelevisionDetail: Decodable {
    let ID: Int?
    let DisplayName: String?
    let HtmlContent: String?
    let Url: String?
    let LastChanged: Date?
}

// MARK: - License Plate

struct LicensePlateResponse: Decodable {
    let ID_Employee: Int?
    let Displayname: String?
    let LicensePlate: String?
}

// MARK: - Employee Settings (Client.Api)

struct EmployeeSettings: Codable {
    let favoriteModuleFlags: FavoriteModuleFlags?
    let modules: [ModuleSettings]?
}

struct FavoriteModuleFlags: Codable {
    let introShown: Bool?
    let infoHighlighted: Bool?
    let suggestionShown: Bool?
}

struct ModuleSettings: Codable {
    let moduleId: Int?
    let favoriteOrder: Int?
}

struct UpdateEmployeeSettingsRequest: Encodable {
    let ID_Login: String
    let Settings: EmployeeSettings
}

// MARK: - Data List

struct DataListResponse: Decodable {
    let ID_NewFormCompanyMenuItem: Int?
    let Description: String?
    let EmptyDataText: String?
    let IsNew: Bool?
    let IsDetail: Bool?
    let OneRecord: Bool?
    let NewCrossLink: String?
    let Items: [DataListItem]?
}

struct DataListItem: Decodable, Identifiable {
    let ID: String?
    let DisplayName: String?
    let Description: String?
    let ID_Document: Int?
    let DocumentHash: String?
    let DocumentUrl: String?
    let Date: String?
    let DateType: String?
    let Highlighted: Bool?
    let DetailCrossLink: String?
    let ID_ListType: String?

    var id: String { self.ID ?? UUID().uuidString }
}

struct DataDetailResponse: Decodable {
    let ID_EditFormCompanyMenuItem: Int?
    let DisplayName: String?
    let UserInsert: String?
    let IsUpdate: Bool?
    let IsDelete: Bool?
    let DateCreated: String?
    let EditCrossLink: String?
    let Items: [DataDetailItem]?
}

struct DataDetailItem: Decodable, Identifiable {
    let DisplayName: String?
    let Value: String?

    var id: String { DisplayName ?? UUID().uuidString }
}

// MARK: - Form Items

struct FormFieldDefinition: Decodable, Identifiable {
    let ID: Int?
    let ID_CompanyForm: Int?
    let ID_FormItemType: String?
    let ID_FormItemParent: Int?
    let DisplayName: String?
    let Description: String?
    let Placeholder: String?
    let IsRequired: Bool?
    let DefaultValue: String?
    let ID_Document: Int?
    let DocumentHash: String?
    let DocumentUrl: String?
    let CheckBoxRequiredValue: Bool?
    let Options: [FormSelectOption]?
    let Order: Int?
    let Name: String?

    var id: Int { self.ID ?? 0 }
}

struct FormSelectOption: Decodable, Identifiable {
    let ID: Int?
    let DisplayName: String?
    let FormItemOptionDisplayName: String?
    let Description: String?
    let ParentValue: String?
    let Name: String?
    let Order: Int?

    var id: Int { self.ID ?? 0 }
    var displayText: String { DisplayName ?? FormItemOptionDisplayName ?? "" }
}

// MARK: - Company Languages (Client.Api)

struct CompanyLanguage: Decodable, Identifiable {
    let id: String?
    let caption: String?
    let code: String?
    let isBase: Bool?
}

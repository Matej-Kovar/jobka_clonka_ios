import Foundation

// MARK: - Login

struct LoginResponse: Decodable {
    let ID_Login: String?
    let ID_PersistentLogin: String?
    let DisplayName: String?
    let ID_User: Int?
    let ID_Language: String?
    let ID_Employee: Int?
    let Lang: String?
    let IsFirstLogin: Bool?
    let IsTester: Bool?
    let Initials: String?
    let Color: String?
    let ID_Document: Int?
    let DocumentHash: String?
    let PersonalNumber: String?
    let Phone: String?
    let Email: String?
    let QrCode: String?
    let NoteJson: String?
    let Languages: [LanguageItem]?
    let ValidationMessages: [ValidationMessage]?
}

struct LanguageItem: Decodable, Identifiable {
    let ID: String?
    let Caption: String?
    let Code: String?
    let IsBase: Bool?

    var id: String { self.ID ?? UUID().uuidString }
}

// MARK: - Employee Profile (Client.Api)

struct EmployeeProfile: Decodable {
    let displayName: String?
    let userId: Int?
    let employeeId: Int?
    let personalNumber: String?
    let qrCode: String?
    let phone: String?
    let email: String?
    let isTester: Bool?
    let noteJson: String?
    let languageId: String?
    let lang: String?
    let initials: String?
    let color: String?
    let documentId: Int?
    let documentHash: String?
}

// MARK: - Company State

struct CompanyState: Decodable {}

// MARK: - Registration

struct RegisterRequest: Encodable {
    let RegisterKey: String
    let DisplayName: String
    let PersonalNumber: String
    let Email: String?
    let Campaign: String?
    let Lang: String?
}

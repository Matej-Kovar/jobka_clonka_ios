import Foundation

struct ConversationListItem: Decodable, Identifiable {
    let ID_Employee: Int?
    let Employee: String?
    let Initials: String?
    let Color: String?
    let ID_MessageGroup: Int?
    let MessageGroup: String?
    let Message: String?
    let Sent: Date?
    let ID_Document: Int?
    let IsDocument: Bool?
    let DocumentHash: String?
    let IsOut: Bool?
    let IsRead: Bool?
    let IsLogged: Bool?
    let ID_Member: Int?
    let ID_MemberPermission: String?
    let MemberCount: Int?
    let IsNotify: Bool?
    let IsLeavingEnabled: Bool?

    var id: String {
        if let groupId = ID_MessageGroup { return "group-\(groupId)" }
        if let empId = ID_Employee { return "dm-\(empId)" }
        return UUID().uuidString
    }

    var isGroup: Bool { ID_MessageGroup != nil }
    var displayTitle: String {
        isGroup ? (MessageGroup ?? "Group") : (Employee ?? "Unknown")
    }
}

struct ChatMessage: Decodable, Identifiable {
    let ID: Int
    let Message: String?
    let Sent: Date?
    let ID_Document: Int?
    let Hash: String?
    let IsOut: Bool?
    let Employee: String?
    let EmployeeInicial: String?
    let EmployeeColor: String?

    var id: Int { self.ID }
    var displayName: String? { Employee }
    var initials: String? { EmployeeInicial }
    var color: String? { EmployeeColor }
}

struct SendMessageRequest: Encodable {
    let ID_Login: String
    let ID_EmployeeReceiver: Int?
    let ID_MessageGroup: Int?
    let Message: String?
    let ID_CompanyMenuItem: Int?
}

struct MessageGroupCreateRequest: Encodable {
    let ID_Login: String
    let DisplayName: String
    let Description: String?
    let ID_CompanyMenuItem: Int?
}

struct ChatEmployee: Decodable, Identifiable {
    let ID: Int
    let User: String?
    let Initials: String?
    let Color: String?
    let Group: String?
    let ID_Document: Int?
    let DocumentHash: String?

    var id: Int { self.ID }
    var displayName: String { User ?? "Unknown" }
    var initials: String { Initials ?? String(displayName.prefix(1)) }
}

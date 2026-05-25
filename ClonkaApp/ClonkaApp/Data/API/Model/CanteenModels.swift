import Foundation

struct CanteenItem: Decodable, Identifiable, Hashable {
    let ID: Int
    let DisplayName: String?
    let ExternalId: String?

    var id: Int { self.ID }

    static func == (lhs: CanteenItem, rhs: CanteenItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct CanteenLoginResponse: Decodable {
    let ExternalLogin: String?
    let ExternalPersonId: String?
}

struct CanteenSlot: Decodable, Identifiable {
    let ID_CarteSlot: Int?
    let DisplayName: String?
    let ExternalId: String?
    let Sections: [CanteenSection]?

    var id: Int { ID_CarteSlot ?? 0 }
}

struct CanteenSection: Decodable, Identifiable {
    let ID_CarteSection: Int?
    let DisplayName: String?
    let ExternalId: String?
    let Choices: [CanteenChoice]?

    var id: Int { ID_CarteSection ?? 0 }
}

struct CanteenChoice: Decodable, Identifiable {
    let ID_Choice: Int?
    let DisplayName: String?
    let Description: String?
    let FullPrice: Double?
    let AllowedPrice: Double?
    let StateCount: Int?
    let ExternalId: String?
    let CanOrder: Bool?

    var id: Int { ID_Choice ?? 0 }
}

struct CanteenOrderRequest: Encodable {
    let ID_Login: String
    let Day: String
    let CarteChoices: [CanteenOrderChoice]
    let ID_Canteen: Int?
    let ExternalCanteenId: String?
    let ExternalLogin: String?
    let ExternalPersonId: String?
}

struct CanteenOrderChoice: Encodable {
    let ID_CarteChoice: Int
    let StateCount: Int
    let ExternalSlotId: String?
    let ExternalSectionId: String?
    let ExternalChoiceId: String?
}

struct CanteenLoginRequest: Encodable {
    let ID_Login: String
    let Password: String
    let ID_CompanyMenuItem: Int?
}

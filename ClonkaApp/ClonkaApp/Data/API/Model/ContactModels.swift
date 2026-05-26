import Foundation

struct ContactsResponse: Decodable {
    let IsChange: Bool?
    let LastUpdate: String?
    let Data: [ContactItem]?
}

struct ContactItem: Decodable, Identifiable {
    let ID: Int
    let DisplayName: String?
    let FirstName: String?
    let LastName: String?
    let Initials: String?
    let JobTitle: String?
    let Department: String?
    let Phone: String?
    let SecondPhone: String?
    let Email: String?
    let SecondEmail: String?
    let Color: String?
    let ID_Document: Int?
    let DocumentHash: String?

    var id: Int { self.ID }
}

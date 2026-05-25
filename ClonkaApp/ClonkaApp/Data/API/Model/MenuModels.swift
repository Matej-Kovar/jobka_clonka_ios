import Foundation

// MARK: - Menu Navigation

struct MenuNavigationItem: Decodable, Identifiable {
    let ID: Int
    let Icon: String?
    let IconUnicode: String?
    let ID_MenuItem: String?
    let MenuItem: String?
    let DisplayName: String?
    let TileColor: String?
    let HasGroup: Bool?
    let IsDisable: Bool?
    let MenuType_ResourceName: String?
    let Order: Int?
    let Route: String?

    var id: Int { self.ID }
}

struct MenuBadgeCount: Decodable {
    let ID_CompanyMenuItem: Int
    let ID_MenuItem: String?
    let NumberOfNew: Int?
}

// MARK: - CheckPrivateData

struct CheckPrivateDataResponse: Decodable {
    let Url: String?
    let IsChange: Bool?
    let Date: String?
}

// MARK: - XML Configuration models

struct XMLConfiguration {
    var company: XMLCompany?
    var menuItems: [XMLMenuItem]

    init() {
        company = nil
        menuItems = []
    }
}

struct XMLCompany {
    var displayName: String?
    var companyColor: String?
    var backgroundColor: String?
    var companyAccentColor: String?
}

struct XMLMenuItem: Identifiable {
    let itemId: Int
    let title: String
    let order: Int?
    let parentItemId: Int?
    let icon: String?
    let iconName: String?
    let fontFamily: String?
    let tileColor: TileColor?
    let textColor: TileColor?
    let iconColor: TileColor?
    let itemType: String
    let isEnabled: Bool
    let numberOfNew: Int
    let params: [String: String]

    var id: Int { itemId }
}

struct TileColor {
    let alpha: Int
    let red: Int
    let green: Int
    let blue: Int

    var color: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }
}

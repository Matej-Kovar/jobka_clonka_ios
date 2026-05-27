import SwiftUI

enum L10n: String {
    case App_Name
    case App_Description
    case App_NameDetail
    
    var key: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }
    
}

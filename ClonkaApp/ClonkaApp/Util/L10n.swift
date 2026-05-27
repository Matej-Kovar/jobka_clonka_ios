import SwiftUI

enum L10n: String {
    case App_Name
    case App_Description
    case App_NameDetail
    case Auth_AccessCode
    case Auth_Camera
    case Auth_EnterAccessCode
    case Auth_EnterDeveloperPassword
    case Auth_EnterPersonalNumber
    case Auth_ErrorNoAC
    case Auth_ErrorNoPN
    case Auth_LoggingIn
    case Auth_Login
    case Auth_Manual
    case Auth_PersonalNumber
    case Auth_SavedAccounts
    case Auth_ScanQRCode
    case Cancel
    case Auth_Password
    case DeveloperMode
    case Activate
    case Auth_PN
    case Delete
    
    var key: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }
    
}

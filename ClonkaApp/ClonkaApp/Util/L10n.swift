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
    case UnknownModule_Title
    case UnknownModule_Description
    case MaintenanceMode_Title
    case MaintenanceMode_Description
    case Loading
    case NoItemsFound
    case Error_Generic
    case Error_TryAgain
    case Menu_SearchMenu
    case Menu_Favorites
    case Menu_NoItems
    case Post_NoPosts
    case Post_Title
    case Post_Attachments
    case Post_Approved
    case Post_ApproveMessage
    case Post_Approve
    case Post_Detail
    case Survey_NotAvailable
    case Survey_ListTitle
    case Survey_Questionnaire
    case Survey_Query
    case Survey_Title
    case Survey_Answered
    case Survey_Open
    case Survey_Anonymous
    case Survey_Archive
    case Survey_New
    case Survey_Question
    case Survey_QuestionCount
    case Survey_Required
    case Image_Fail
    case Image_URL
    case Survey_SelectAll
    case Survey_Type
    case Back
    case Next
    case Submit
    case Survey_Submitted
    case Survey_Thanks
    case Post_ApproveFail
    case Post_Notice
    case Auth_EnterQRCode
    case Auth_QRCAC
    case Unknown
    case Empty
    case Confirm
    case Close
    case Menu_Title
    case AboutApp_Version
    case AboutApp_Developer
    case AboutApp_DeveleperMode
    case Profile_User
    case Profile_Details
    case Profile_TesterAccount
    case Profile_RemovePhoto
    case Profile_About
    case Profile_Settings
    case Profile_Logout
    case Profile_Title
    case Done
    case AboutApp_Title
    case Settings_Appearance
    case Settings_Theme
    case Settings_ThemeSystem
    case Settings_ThemeDark
    case Settings_ThemeLight
    case Settings_Language
    case Settings_AboutApp
    case Settings_Title
    
    var key: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }
    
    var string: String {
        String(localized: LocalizedStringResource(stringLiteral: rawValue))
    }
    
    /// Format a localized string with parameters (e.g., %1$lld, %2$lld)
    /// Usage: L10n.Survey_QuestionCount.formatted(with: current, total)
    func formatted(with args: CVarArg...) -> String {
        String(format: string, arguments: args)
    }
    
}

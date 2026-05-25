import Foundation

class XMLConfigurationParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var config = XMLConfiguration()

    // Parsing state
    private var currentElement = ""
    private var currentText = ""
    private var parsingCompany = false
    private var parsingMenuItems = false
    private var parsingMenuItem = false
    private var parsingTileColor = false
    private var parsingTextColor = false
    private var parsingIconColor = false
    private var parsingParams = false
    private var parsingParamItem = false
    private var parsingParamKey = false
    private var parsingParamValue = false

    // Current menu item being built
    private var currentItemId: Int = 0
    private var currentTitle = ""
    private var currentOrder: Int? = nil
    private var currentParentItemId: Int? = nil
    private var currentIcon: String? = nil
    private var currentIconName: String? = nil
    private var currentFontFamily: String? = nil
    private var currentItemType = ""
    private var currentIsEnabled = true
    private var currentNumberOfNew = 0
    private var currentParams: [String: String] = [:]
    private var currentParamKey = ""
    private var currentParamValue = ""

    // Current color components
    private var colorAlpha = 255
    private var colorRed = 0
    private var colorGreen = 0
    private var colorBlue = 0

    // Temporary color storage for current item
    private var currentTileColor: TileColor?
    private var currentTextColor: TileColor?
    private var currentIconColor: TileColor?

    // Company fields
    private var companyDisplayName: String? = nil
    private var companyColor: String? = nil
    private var backgroundColor: String? = nil

    init(data: Data) {
        self.data = data
        super.init()
    }

    func parse() -> XMLConfiguration {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return config
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser, didStartElement elementName: String,
        namespaceURI: String?, qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "Company":
            parsingCompany = true
        case "MenuItems":
            parsingMenuItems = true
        case "MenuItemData":
            parsingMenuItem = true
            resetCurrentItem()
        case "TileColor":
            if parsingMenuItem { parsingTileColor = true; resetColor() }
        case "TextColor":
            if parsingMenuItem { parsingTextColor = true; resetColor() }
        case "IconColor":
            if parsingMenuItem { parsingIconColor = true; resetColor() }
        case "Params":
            if parsingMenuItem { parsingParams = true }
        case "item":
            if parsingParams {
                parsingParamItem = true
                currentParamKey = ""
                currentParamValue = ""
            }
        case "key":
            if parsingParamItem { parsingParamKey = true }
        case "value":
            if parsingParamItem { parsingParamValue = true }
        default:
            break
        }

        if attributes["xsi:nil"] == "true" {
            currentText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser, didEndElement elementName: String,
        namespaceURI: String?, qualifiedName: String?
    ) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Params parsing (must come before other sections)
        if parsingParams {
            switch elementName {
            case "key":
                if parsingParamKey {
                    currentParamKey = text
                    parsingParamKey = false
                }
            case "value":
                if parsingParamValue {
                    currentParamValue = text
                    parsingParamValue = false
                }
            case "string":
                // XmlSerializer wraps string values in <string> tags
                if parsingParamKey { currentParamKey = text }
                else if parsingParamValue { currentParamValue = text }
            case "anyType":
                // XmlSerializer wraps object values in <anyType> tags
                if parsingParamValue { currentParamValue = text }
            case "item":
                if parsingParamItem && !currentParamKey.isEmpty {
                    currentParams[currentParamKey] = currentParamValue
                }
                parsingParamItem = false
            case "Params":
                parsingParams = false
            default: break
            }
            return
        }

        // Company fields
        if parsingCompany && !parsingMenuItems {
            switch elementName {
            case "DisplayName": companyDisplayName = text
            case "CompanyColor": companyColor = text
            case "BackgroundColor": backgroundColor = text
            case "Company":
                config.company = XMLCompany(
                    displayName: companyDisplayName,
                    companyColor: companyColor,
                    backgroundColor: backgroundColor,
                    companyAccentColor: nil
                )
                parsingCompany = false
            default: break
            }
        }

        // Color fields (inside TileColor/TextColor/IconColor)
        if parsingTileColor || parsingTextColor || parsingIconColor {
            switch elementName {
            case "Alpha": colorAlpha = Int(text) ?? 255
            case "Red": colorRed = Int(text) ?? 0
            case "Green": colorGreen = Int(text) ?? 0
            case "Blue": colorBlue = Int(text) ?? 0
            case "TileColor", "TextColor", "IconColor":
                let color = TileColor(
                    alpha: colorAlpha, red: colorRed,
                    green: colorGreen, blue: colorBlue)
                switch elementName {
                case "TileColor":
                    currentTileColor = color
                    parsingTileColor = false
                case "TextColor":
                    currentTextColor = color
                    parsingTextColor = false
                case "IconColor":
                    currentIconColor = color
                    parsingIconColor = false
                default: break
                }
            default: break
            }
            return
        }

        // Menu item fields
        if parsingMenuItem {
            switch elementName {
            case "Title": currentTitle = text
            case "ItemId": currentItemId = Int(text) ?? 0
            case "Order": currentOrder = Int(text)
            case "IdParentItem":
                currentParentItemId = text.isEmpty ? nil : Int(text)
            case "Icon": currentIcon = text.isEmpty ? nil : text
            case "IconName": currentIconName = text.isEmpty ? nil : text
            case "FontFamily": currentFontFamily = text.isEmpty ? nil : text
            case "ItemType": currentItemType = text
            case "IsEnabled": currentIsEnabled = text.lowercased() == "true"
            case "NumberOfNew": currentNumberOfNew = Int(text) ?? 0
            case "MenuItemData":
                let item = XMLMenuItem(
                    itemId: currentItemId,
                    title: currentTitle,
                    order: currentOrder,
                    parentItemId: currentParentItemId,
                    icon: currentIcon,
                    iconName: currentIconName,
                    fontFamily: currentFontFamily,
                    tileColor: currentTileColor,
                    textColor: currentTextColor,
                    iconColor: currentIconColor,
                    itemType: currentItemType,
                    isEnabled: currentIsEnabled,
                    numberOfNew: currentNumberOfNew,
                    params: currentParams
                )
                config.menuItems.append(item)
                parsingMenuItem = false
            default: break
            }
        }

        if elementName == "MenuItems" {
            parsingMenuItems = false
        }
    }

    private func resetCurrentItem() {
        currentItemId = 0
        currentTitle = ""
        currentOrder = nil
        currentParentItemId = nil
        currentIcon = nil
        currentIconName = nil
        currentFontFamily = nil
        currentItemType = ""
        currentIsEnabled = true
        currentNumberOfNew = 0
        currentTileColor = nil
        currentTextColor = nil
        currentIconColor = nil
        currentParams = [:]
    }

    private func resetColor() {
        colorAlpha = 255
        colorRed = 0
        colorGreen = 0
        colorBlue = 0
    }
}

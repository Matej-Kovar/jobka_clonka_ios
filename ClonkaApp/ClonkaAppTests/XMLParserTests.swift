import XCTest
@testable import ClonkaApp

final class XMLParserTests: XCTestCase {

    func testParseValidXML() {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <XMLConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <Company>
            <DisplayName>Test Company</DisplayName>
            <CompanyColor>#FF0000</CompanyColor>
            <BackgroundColor>#FFFFFF</BackgroundColor>
          </Company>
          <MenuItems>
            <MenuItemData>
              <Title>About</Title>
              <ItemType>AboutApp</ItemType>
              <ItemId>100</ItemId>
              <Order>1</Order>
              <IsEnabled>true</IsEnabled>
              <NumberOfNew>5</NumberOfNew>
              <IdParentItem xsi:nil="true" />
              <TileColor><Alpha>255</Alpha><Red>255</Red><Green>0</Green><Blue>0</Blue></TileColor>
              <TextColor><Alpha>255</Alpha><Red>255</Red><Green>255</Green><Blue>255</Blue></TextColor>
              <IconColor><Alpha>255</Alpha><Red>255</Red><Green>255</Green><Blue>255</Blue></IconColor>
            </MenuItemData>
            <MenuItemData>
              <Title>Settings</Title>
              <ItemType>Settings</ItemType>
              <ItemId>101</ItemId>
              <Order>2</Order>
              <IsEnabled>true</IsEnabled>
              <NumberOfNew>0</NumberOfNew>
              <IdParentItem xsi:nil="true" />
              <TileColor><Alpha>255</Alpha><Red>0</Red><Green>0</Green><Blue>255</Blue></TileColor>
              <TextColor><Alpha>255</Alpha><Red>255</Red><Green>255</Green><Blue>255</Blue></TextColor>
              <IconColor><Alpha>255</Alpha><Red>255</Red><Green>255</Green><Blue>255</Blue></IconColor>
            </MenuItemData>
          </MenuItems>
        </XMLConfiguration>
        """.data(using: .utf8)!

        let parser = XMLConfigurationParser(data: xml)
        let config = parser.parse()

        XCTAssertEqual(config.company?.displayName, "Test Company")
        XCTAssertEqual(config.company?.companyColor, "#FF0000")
        XCTAssertEqual(config.menuItems.count, 2)

        let about = config.menuItems.first { $0.itemType == "AboutApp" }
        XCTAssertNotNil(about)
        XCTAssertEqual(about?.title, "About")
        XCTAssertEqual(about?.itemId, 100)
        XCTAssertEqual(about?.order, 1)
        XCTAssertEqual(about?.numberOfNew, 5)
        XCTAssertNotNil(about?.tileColor)
        XCTAssertEqual(about?.tileColor?.red, 255)
        XCTAssertEqual(about?.tileColor?.green, 0)
        XCTAssertEqual(about?.tileColor?.blue, 0)

        let settings = config.menuItems.first { $0.itemType == "Settings" }
        XCTAssertNotNil(settings)
        XCTAssertEqual(settings?.title, "Settings")
        XCTAssertEqual(settings?.itemId, 101)
        XCTAssertEqual(settings?.numberOfNew, 0)
    }

    func testParseFolderHierarchy() {
        let xml = """
        <?xml version="1.0"?>
        <XMLConfiguration>
          <Company><DisplayName>Test</DisplayName></Company>
          <MenuItems>
            <MenuItemData>
              <Title>Folder</Title>
              <ItemType>Folder</ItemType>
              <ItemId>1</ItemId>
              <Order>1</Order>
              <IsEnabled>true</IsEnabled>
              <NumberOfNew>0</NumberOfNew>
            </MenuItemData>
            <MenuItemData>
              <Title>Child Item</Title>
              <ItemType>PostList</ItemType>
              <ItemId>2</ItemId>
              <Order>1</Order>
              <IsEnabled>true</IsEnabled>
              <NumberOfNew>3</NumberOfNew>
              <IdParentItem>1</IdParentItem>
            </MenuItemData>
          </MenuItems>
        </XMLConfiguration>
        """.data(using: .utf8)!

        let parser = XMLConfigurationParser(data: xml)
        let config = parser.parse()

        XCTAssertEqual(config.menuItems.count, 2)

        let rootItems = config.menuItems.filter { $0.parentItemId == nil }
        XCTAssertEqual(rootItems.count, 1)
        XCTAssertEqual(rootItems.first?.title, "Folder")

        let childItems = config.menuItems.filter { $0.parentItemId == 1 }
        XCTAssertEqual(childItems.count, 1)
        XCTAssertEqual(childItems.first?.title, "Child Item")
        XCTAssertEqual(childItems.first?.numberOfNew, 3)
    }

    func testParseEmptyXML() {
        let xml = """
        <?xml version="1.0"?>
        <XMLConfiguration>
          <Company></Company>
          <MenuItems></MenuItems>
        </XMLConfiguration>
        """.data(using: .utf8)!

        let parser = XMLConfigurationParser(data: xml)
        let config = parser.parse()

        XCTAssertTrue(config.menuItems.isEmpty)
    }

    func testParseDisabledItems() {
        let xml = """
        <?xml version="1.0"?>
        <XMLConfiguration>
          <Company><DisplayName>Co</DisplayName></Company>
          <MenuItems>
            <MenuItemData>
              <Title>Hidden</Title>
              <ItemType>PostList</ItemType>
              <ItemId>10</ItemId>
              <Order>1</Order>
              <IsEnabled>false</IsEnabled>
              <NumberOfNew>0</NumberOfNew>
            </MenuItemData>
          </MenuItems>
        </XMLConfiguration>
        """.data(using: .utf8)!

        let parser = XMLConfigurationParser(data: xml)
        let config = parser.parse()

        XCTAssertEqual(config.menuItems.count, 1)
        XCTAssertFalse(config.menuItems.first!.isEnabled)
    }

    func testParseBackgroundColor() {
        let xml = """
        <?xml version="1.0"?>
        <XMLConfiguration>
          <Company>
            <DisplayName>Colors Inc</DisplayName>
            <CompanyColor>#123456</CompanyColor>
            <BackgroundColor>#ABCDEF</BackgroundColor>
          </Company>
          <MenuItems></MenuItems>
        </XMLConfiguration>
        """.data(using: .utf8)!

        let parser = XMLConfigurationParser(data: xml)
        let config = parser.parse()

        XCTAssertEqual(config.company?.displayName, "Colors Inc")
        XCTAssertEqual(config.company?.companyColor, "#123456")
        XCTAssertEqual(config.company?.backgroundColor, "#ABCDEF")
    }
}

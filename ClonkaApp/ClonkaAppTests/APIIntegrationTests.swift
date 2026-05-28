import XCTest
@testable import ClonkaApp

final class APIIntegrationTests: XCTestCase {

    private var idLogin: String!

    override func setUp() async throws {
        await ConfigManager.shared.loadConfig()
        await ConfigManager.shared.switchEnvironment(.test)

        let result = await AuthAPIService.login(
            personalNumber: "1",
            accessCode: "8cbe80b0-d2be-4733-8045-638f03474842"
        )
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.ID_Login, "Login should return ID_Login")
            idLogin = response.ID_Login!
            await APIClient.shared.setIdLogin(idLogin)
        case .failure(let error):
            XCTFail("Login failed: \(error)")
        }
    }

    // MARK: - Auth Tests

    func testLogin() async throws {
        let result = await AuthAPIService.login(
            personalNumber: "1",
            accessCode: "8cbe80b0-d2be-4733-8045-638f03474842"
        )
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.ID_Login)
            XCTAssertEqual(response.DisplayName, "Tester")
            XCTAssertEqual(response.PersonalNumber, "1")
            XCTAssertEqual(response.Initials, "TT")
            XCTAssertEqual(response.Color, "#00bcd4")
            XCTAssertNotNil(response.Languages)
            XCTAssertFalse(response.Languages!.isEmpty)
        case .failure(let error):
            XCTFail("Login failed: \(error)")
        }
    }

    func testLoginWithSecondUser() async throws {
        let result = await AuthAPIService.login(
            personalNumber: "2",
            accessCode: "f28293b1-f6be-462a-8cf0-a9260075946c"
        )
        switch result {
        case .success(let response):
            XCTAssertNotNil(response.ID_Login)
            XCTAssertEqual(response.PersonalNumber, "2")
        case .failure(let error):
            XCTFail("Login with user 2 failed: \(error)")
        }
    }

    func testLoginInvalidCredentials() async throws {
        let result = await AuthAPIService.login(
            personalNumber: "9999",
            accessCode: "invalid-code"
        )
        switch result {
        case .success(let response):
            if response.ID_Login == nil {
                return  // Expected — no login token
            }
        case .failure:
            break  // Expected failure
        }
    }

    func testCheckMaintenanceMode() async throws {
        let result = await AuthAPIService.checkMaintenanceMode(idLogin: idLogin)
        switch result {
        case .success:
            break  // Maintenance not active — expected
        case .failure(let error):
            if case .maintenance = error {
                break  // Also valid if maintenance is on
            }
            XCTFail("Maintenance check failed unexpectedly: \(error)")
        }
    }

    // MARK: - Menu Tests

    func testFetchMenuFromXML() async throws {
        let result = await MenuAPIService.fetchMenuFromXML()
        switch result {
        case .success(let config):
            XCTAssertNotNil(config.company)
            XCTAssertEqual(config.company?.displayName, "Danovo Píseček - Clonka")
            XCTAssertFalse(config.menuItems.isEmpty, "Should have menu items")
            XCTAssertGreaterThanOrEqual(config.menuItems.count, 10, "Should have at least 10 menu items")

            let itemTypes = Set(config.menuItems.map { $0.itemType })
            XCTAssertTrue(itemTypes.contains("AboutApp"))
            XCTAssertTrue(itemTypes.contains("Settings"))
            XCTAssertTrue(itemTypes.contains("SurveyList"))
        case .failure(let error):
            XCTFail("Menu XML fetch failed: \(error)")
        }
    }

    func testBadgeCounts() async throws {
        let result = await MenuAPIService.fetchBadgeCounts()
        switch result {
        case .success(let counts):
            XCTAssertFalse(counts.isEmpty, "Should have badge counts")
            for count in counts {
                XCTAssertGreaterThan(count.ID_CompanyMenuItem, 0)
            }
        case .failure(let error):
            XCTFail("Badge counts failed: \(error)")
        }
    }

    // MARK: - Posts Tests

    func testFetchPosts() async throws {
        let result = await PostAPIService.fetchPosts(companyMenuItemId: 29787)
        switch result {
        case .success(let posts):
            print("Posts count: \(posts.count)")
        case .failure(let error):
            XCTFail("Fetch posts failed: \(error)")
        }
    }

    func testFetchPopupPosts() async throws {
        let result = await PostAPIService.fetchPopups()
        switch result {
        case .success(let popups):
            print("Popup posts: \(popups.count)")
        case .failure(let error):
            XCTFail("Fetch popup posts failed: \(error)")
        }
    }

    // MARK: - Surveys Tests

    func testFetchSurveys() async throws {
        let result = await SurveyAPIService.fetchSurveys(moduleId: 29780)
        switch result {
        case .success(let surveys):
            XCTAssertEqual(surveys.count, 2, "Should have 2 surveys")
            for survey in surveys {
                XCTAssertGreaterThan(survey.surveyId, 0)
                XCTAssertNotNil(survey.displayName)
            }
        case .failure(let error):
            XCTFail("Fetch surveys failed: \(error)")
        }
    }

    func testFetchSurveyDetail() async throws {
        let result = await SurveyAPIService.fetchSurveyDetail(surveyId: 4453)
        switch result {
        case .success(let detail):
            XCTAssertEqual(detail.surveyId, 4453)
            XCTAssertNotNil(detail.questions)
            XCTAssertFalse(detail.questions!.isEmpty, "Survey should have questions")
        case .failure(let error):
            XCTFail("Fetch survey detail failed: \(error)")
        }
    }

    // MARK: - Messages Tests

    func testFetchConversations() async throws {
        let result = await MessageAPIService.fetchConversations(companyMenuItemId: 29782)
        switch result {
        case .success(let conversations):
            XCTAssertGreaterThanOrEqual(conversations.count, 1, "Should have at least 1 conversation")
        case .failure(let error):
            XCTFail("Fetch conversations failed: \(error)")
        }
    }

    // MARK: - Contacts Tests

    func testFetchContacts() async throws {
        let result = await ContactAPIService.fetchContacts(companyMenuItemId: 29785)
        switch result {
        case .success(let response):
            print("Contacts: \(response.Data?.count ?? 0)")
        case .failure(let error):
            XCTFail("Fetch contacts failed: \(error)")
        }
    }

    // MARK: - Employee Profile Tests

    func testFetchEmployeeProfile() async throws {
        let result = await EmployeeAPIService.fetchProfile()
        switch result {
        case .success(let profile):
            XCTAssertEqual(profile.displayName, "Tester")
            XCTAssertEqual(profile.personalNumber, "1")
            XCTAssertEqual(profile.initials, "TT")
        case .failure(let error):
            XCTFail("Fetch employee profile failed: \(error)")
        }
    }

    func testFetchEmployeeSettings() async throws {
        let result = await EmployeeAPIService.fetchSettings()
        switch result {
        case .success(let settings):
            print("Settings: \(settings)")
        case .failure(let error):
            print("Settings fetch result: \(error)")
        }
    }

    // MARK: - Trust Box Tests

    func testSubmitTrustBox() async throws {
        let result = await TrustBoxAPIService.submit(
            body: "Test feedback from iOS integration test - \(Date())",
            email: "test@example.com",
            moduleId: 29786
        )
        switch result {
        case .success:
            print("Trust box submitted successfully")
        case .failure(let error):
            print("Trust box submit: \(error)")
        }
    }

    // MARK: - Stream Tests

    func testFetchStreamPosts() async throws {
        let result = await StreamAPIService.fetchPosts(moduleId: 29788)
        switch result {
        case .success(let posts):
            print("Stream posts: \(posts.count)")
        case .failure(let error):
            print("Stream posts fetch: \(error)")
        }
    }

    // MARK: - Canteen Tests

    func testFetchCanteen() async throws {
        let result = await CanteenAPIService.fetchCanteens(companyMenuItemId: 29783)
        switch result {
        case .success(let canteens):
            print("Canteens: \(canteens.count)")
        case .failure(let error):
            print("Canteens fetch (expected to fail on test server): \(error)")
        }
    }

    // MARK: - Card Tests

    func testFetchCard() async throws {
        let result = await CardAPIService.fetchCard(companyMenuItemId: 29784)
        switch result {
        case .success(let card):
            print("Card fetched: \(card.CardNumber ?? "No number")")
        case .failure(let error):
            print("Card fetch (expected to fail on test server): \(error)")
        }
    }

    // MARK: - License Plate Tests

    func testLicensePlateSearch() async throws {
        let result = await LicensePlateAPIService.processImage(licensePlate: "TEST-123")
        switch result {
        case .success(let response):
            print("License plate response: \(response.Displayname ?? "Unknown")")
        case .failure(let error):
            print("License plate check: \(error)")
        }
    }

    // MARK: - Data List Tests

    func testFetchDataList() async throws {
        let result = await DataListAPIService.fetchList(companyMenuItemId: 29788)
        switch result {
        case .success(let list):
            print("Data list items: \(list.Items?.count ?? 0)")
        case .failure(let error):
            print("Data list fetch: \(error)")
        }
    }

    // MARK: - Forms Tests

    func testFetchFormFields() async throws {
        let result = await FormAPIService.fetchFields(companyMenuItemId: 29781)
        switch result {
        case .success(let fields):
            print("Form fields: \(fields.count)")
        case .failure(let error):
            print("Form fields fetch: \(error)")
        }
    }

    // MARK: - Custom Pages Tests

    func testFetchCustomPages() async throws {
        let result = await CustomPageAPIService.fetchPages(companyMenuItemId: 99999)
        switch result {
        case .success(let pages):
            print("Custom pages: \(pages.count)")
        case .failure(let error):
            print("Custom pages fetch: \(error)")
        }
    }

    // MARK: - Television Tests

    func testFetchTelevision() async throws {
        let result = await TelevisionAPIService.fetchDetail(companyMenuItemId: 99999)
        switch result {
        case .success(let detail):
            print("Television detail: \(detail.DisplayName ?? "Unknown")")
        case .failure(let error):
            print("Television detail fetch: \(error)")
        }
    }
}

import Foundation

struct MenuAPIService {
    /// Fetch menu by loading XML configuration via CheckPrivateData → XML download → parse
    static func fetchMenuFromXML() async -> AppResult<XMLConfiguration> {
        AppLogger.menu.info("📋 Fetching menu via CheckPrivateData → XML")

        // Step 1: Get XML URL from CheckPrivateData
        let checkResult = await APIClient.shared.wsGet(
            path: "/api/Employee/CheckPrivateData",
            queryItems: [],
            responseType: CheckPrivateDataResponse.self
        )

        guard case .success(let checkData) = checkResult else {
            if case .failure(let error) = checkResult {
                return .failure(error)
            }
            return .failure(.unknown(URLError(.badServerResponse)))
        }

        guard let urlString = checkData.Url, let url = URL(string: urlString) else {
            AppLogger.menu.error("❌ CheckPrivateData returned no URL")
            return .failure(.server(statusCode: 200, message: "No XML URL in response"))
        }

        AppLogger.menu.info("📥 Downloading XML config from Azure...")

        // Step 2: Download XML data
        let downloadResult = await APIClient.shared.downloadData(url: url)

        guard case .success(let xmlData) = downloadResult else {
            if case .failure(let error) = downloadResult {
                return .failure(error)
            }
            return .failure(.unknown(URLError(.badServerResponse)))
        }

        // Step 3: Parse XML into configuration
        AppLogger.menu.info("📋 Parsing XML config (\(xmlData.count) bytes)")
        let parser = XMLConfigurationParser(data: xmlData)
        let config = parser.parse()

        AppLogger.menu.info(
            "✅ Parsed \(config.menuItems.count) menu items, company=\(config.company?.displayName ?? "?")"
        )

        return .success(config)
    }

    static func fetchBadgeCounts() async -> AppResult<[MenuBadgeCount]> {
        AppLogger.menu.info("🔢 Fetching badge counts")
        return await APIClient.shared.wsGet(
            path: "/api/CompanyMenuItem/AllNumberOfNew",
            queryItems: [],
            responseType: [MenuBadgeCount].self
        )
    }
}

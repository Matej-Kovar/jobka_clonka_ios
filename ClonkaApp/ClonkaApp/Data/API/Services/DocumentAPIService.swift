import Foundation

struct DocumentAPIService {
    /// Generate a URL for downloading/viewing a document image
    /// Uses the /api/framework/document/detail endpoint from Webservice.Core API
    static func getDocumentImageURL(
        documentId: Int,
        width: Int? = nil,
        height: Int? = nil
    ) async -> URL? {
        let baseURL = await ConfigManager.shared.webserviceURL
        let idLogin = await APIClient.shared.idLogin ?? ""
        
        guard var components = URLComponents(string: baseURL + "/api/framework/document/detail") else {
            return nil
        }
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "ID_Login", value: idLogin),
            URLQueryItem(name: "iD", value: String(documentId))
        ]
        
        if let width = width {
            queryItems.append(URLQueryItem(name: "width", value: String(width)))
        }
        if let height = height {
            queryItems.append(URLQueryItem(name: "height", value: String(height)))
        }
        
        components.queryItems = queryItems
        
        if let url = components.url {
            AppLogger.api.debug("📄 Document URL: \(AppLogger.redactURL(url))")
            return url
        }
        
        return nil
    }
}

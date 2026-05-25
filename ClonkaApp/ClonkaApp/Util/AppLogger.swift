import Foundation
import OSLog

final class AppLogger {
    static let subsystem = "cz.skeleton.clonka"

    // Category-specific loggers
    static let api = Logger(subsystem: subsystem, category: "API")
    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let navigation = Logger(subsystem: subsystem, category: "Navigation")
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let general = Logger(subsystem: subsystem, category: "General")
    static let menu = Logger(subsystem: subsystem, category: "Menu")
    static let lifecycle = Logger(subsystem: subsystem, category: "Lifecycle")

    // Sensitive field redaction
    private static let sensitiveKeys = [
        "idLogin", "ID_Login", "id_login", "password", "token", "accessCode", "Code",
    ]

    static func redact(_ value: String) -> String {
        guard !value.isEmpty else { return "<empty>" }
        let prefix = String(value.prefix(4))
        return "\(prefix)****"
    }

    static func redactURL(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        components.queryItems = components.queryItems?.map { item in
            if sensitiveKeys.contains(where: {
                $0.caseInsensitiveCompare(item.name) == .orderedSame
            }) {
                return URLQueryItem(name: item.name, value: redact(item.value ?? ""))
            }
            return item
        }
        return components.string ?? url.absoluteString
    }

    static func redactBody(_ data: Data?) -> String {
        guard let data = data, let str = String(data: data, encoding: .utf8) else {
            return "<no body>"
        }
        var result = str
        for key in sensitiveKeys {
            let pattern = "(\"\(key)\"\\s*:\\s*\")([^\"]+)(\")"
            if let regex = try? NSRegularExpression(
                pattern: pattern, options: .caseInsensitive)
            {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: "$1****$3")
            }
        }
        return result
    }
}

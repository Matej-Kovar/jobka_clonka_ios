import Foundation

@MainActor
final class ErrorReportStore: ObservableObject {
    static let shared = ErrorReportStore()

    struct ErrorEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let type: EntryType
        let url: String
        let method: String
        let statusCode: Int?
        let duration: TimeInterval?
        let requestBody: String?
        let responseBody: String?
        let errorMessage: String?

        enum EntryType: String {
            case error = "ERROR"
            case slow = "SLOW"
        }
    }

    @Published var entries: [ErrorEntry] = []
    @Published var slowRequestThreshold: TimeInterval = 1.0

    private let maxEntries = 50

    func addError(
        url: String, method: String, statusCode: Int?, duration: TimeInterval? = nil,
        requestBody: String? = nil, responseBody: String? = nil, errorMessage: String?
    ) {
        let entry = ErrorEntry(
            timestamp: Date(), type: .error, url: url, method: method,
            statusCode: statusCode, duration: duration,
            requestBody: requestBody, responseBody: responseBody,
            errorMessage: errorMessage)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries.removeLast() }
        AppLogger.api.error(
            "🔴 API Error: \(method) \(url) → \(statusCode ?? 0) \(errorMessage ?? "")")
    }

    func addSlowRequest(
        url: String, method: String, statusCode: Int?, duration: TimeInterval,
        responseBody: String? = nil
    ) {
        let entry = ErrorEntry(
            timestamp: Date(), type: .slow, url: url, method: method,
            statusCode: statusCode, duration: duration,
            requestBody: nil, responseBody: responseBody,
            errorMessage: "Slow request: \(String(format: "%.1f", duration))s")
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries.removeLast() }
        AppLogger.api.warning(
            "🟡 Slow request: \(method) \(url) took \(String(format: "%.1f", duration))s")
    }

    func clear() { entries.removeAll() }

    func copyToClipboard() -> String {
        entries.map { e in
            "[\(e.type.rawValue)] \(e.timestamp.formatted()) \(e.method) \(e.url)\n  Status: \(e.statusCode ?? 0) Duration: \(e.duration.map { String(format: "%.1f", $0) + "s" } ?? "-")\n  \(e.errorMessage ?? "")"
        }.joined(separator: "\n\n")
    }
}

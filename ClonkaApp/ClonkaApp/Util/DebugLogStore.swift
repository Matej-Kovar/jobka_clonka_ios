import SwiftUI

/// In-app debug log that captures HTTP requests and app-level log entries.
/// Accessible from Developer Tools when developer mode is active.
@MainActor
final class DebugLogStore: ObservableObject {
    static let shared = DebugLogStore()

    enum LogSource: String { case http, app }
    enum LogLevel: String { case info, warn, error }

    struct Entry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let source: LogSource
        let level: LogLevel
        let tag: String
        let message: String
        let detail: String?
        // HTTP-specific
        let method: String?
        let url: String?
        let httpStatus: Int?
        let durationMs: Int?
    }

    @Published var entries: [Entry] = []
    private let maxEntries = 300

    // MARK: - HTTP Logging

    func logHTTP(
        level: LogLevel = .info,
        method: String,
        url: String,
        httpStatus: Int? = nil,
        durationMs: Int? = nil,
        detail: String? = nil
    ) {
        let arrow = level == .error ? "✗" : "←"
        let msg = "\(arrow) \(httpStatus ?? 0) \(method) \(url)"
        append(Entry(
            timestamp: Date(), source: .http, level: level, tag: "http",
            message: msg, detail: detail,
            method: method, url: url, httpStatus: httpStatus, durationMs: durationMs
        ))
    }

    // MARK: - App Logging

    func logApp(tag: String, level: LogLevel, message: String, detail: String? = nil) {
        append(Entry(
            timestamp: Date(), source: .app, level: level, tag: tag,
            message: message, detail: detail,
            method: nil, url: nil, httpStatus: nil, durationMs: nil
        ))
    }

    // MARK: - Queries

    func filtered(source: LogSource? = nil, level: LogLevel? = nil) -> [Entry] {
        entries.filter { e in
            (source == nil || e.source == source) &&
            (level == nil || e.level == level)
        }
    }

    func clear() { entries.removeAll() }

    func copyToClipboard() -> String {
        entries.map { e in
            let parts = [
                "[\(e.timestamp.formatted(date: .omitted, time: .standard))]",
                "[\(e.source.rawValue)]",
                "[\(e.level.rawValue)]",
                "[\(e.tag)]",
                e.message,
                e.durationMs.map { "\($0)ms" } ?? nil,
            ].compactMap { $0 }
            var line = parts.joined(separator: " ")
            if let d = e.detail { line += "\n  \(d)" }
            return line
        }.joined(separator: "\n")
    }

    // MARK: - Private

    private func append(_ entry: Entry) {
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }
}

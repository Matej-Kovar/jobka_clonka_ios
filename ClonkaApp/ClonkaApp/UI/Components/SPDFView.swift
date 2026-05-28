import SwiftUI
import PDFKit

actor PDFLocalFileCache {
    private var byRemoteURL: [String: URL] = [:]

    func get(_ remoteURL: URL) -> URL? {
        let key = remoteURL.absoluteString
        guard let local = byRemoteURL[key] else { return nil }
        if FileManager.default.fileExists(atPath: local.path) {
            return local
        }
        byRemoteURL.removeValue(forKey: key)
        return nil
    }

    func set(_ remoteURL: URL, localURL: URL) {
        byRemoteURL[remoteURL.absoluteString] = localURL
    }
}

enum PDFDocumentResolver {
    private static let cache = PDFLocalFileCache()

    static func resolvePDFURL(from url: URL) -> URL {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let fileParam = components.queryItems?.first(where: { $0.name.lowercased() == "file" })?.value,
              let resolved = decodeNestedURL(from: fileParam) else {
            return url
        }
        return resolved
    }

    static func downloadPDFToTemporaryFile(from url: URL, filePrefix: String) async throws -> URL {
        if let cached = await cache.get(url) {
            return cached
        }

        if url.isFileURL { return url }

        let (data, response) = try await URLSession.shared.data(from: url)
        let contentType = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        let looksLikePDF = data.starts(with: Data("%PDF-".utf8)) || contentType.contains("pdf")

        guard looksLikePDF else {
            throw URLError(.cannotDecodeContentData)
        }

        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(filePrefix)_\(UUID().uuidString).pdf")
        try data.write(to: tmpURL)
        await cache.set(url, localURL: tmpURL)
        return tmpURL
    }

    static func cachedLocalPDF(for url: URL) async -> URL? {
        await cache.get(url)
    }

    static func preloadPDF(from url: URL, filePrefix: String) async {
        _ = try? await downloadPDFToTemporaryFile(from: url, filePrefix: filePrefix)
    }

    private static func decodeNestedURL(from value: String) -> URL? {
        var current = value
        for _ in 0..<3 {
            if let url = URL(string: current), url.scheme != nil {
                return url
            }
            if let decoded = current.removingPercentEncoding, decoded != current {
                current = decoded
            } else {
                break
            }
        }
        return URL(string: current)
    }
}

/// Simple SwiftUI wrapper around PDFKit.PDFView that can load remote or local PDFs.
struct PDFKitView: UIViewRepresentable {
    let url: URL

    final class Coordinator {
        var currentURL: URL?
        var loadingTask: Task<Void, Never>?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if context.coordinator.currentURL == url {
            return
        }

        context.coordinator.currentURL = url
        context.coordinator.loadingTask?.cancel()
        uiView.document = nil

        // Load local file quickly, otherwise fetch remote data.
        if url.isFileURL {
            if let doc = PDFDocument(url: url) {
                uiView.document = doc
                uiView.autoScales = true
                if let firstPage = doc.page(at: 0) {
                    uiView.go(to: firstPage)
                }
            }
            return
        }

        context.coordinator.loadingTask = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }
                if let doc = PDFDocument(data: data) {
                    await MainActor.run {
                        uiView.document = doc
                        uiView.autoScales = true
                        if let firstPage = doc.page(at: 0) {
                            uiView.go(to: firstPage)
                        }
                    }
                }
            } catch {
                if !Task.isCancelled {
                    AppLogger.navigation.error("❌ Failed to load PDF: \(error.localizedDescription)")
                }
            }
        }
    }
}

/// Convenience SwiftUI view that shows a PDF with a close button when used inside a sheet.
struct SPDFViewer: View {
    let url: URL
    let title: String?
    @Environment(\.dismiss) private var dismiss

    init(url: URL, title: String? = nil) {
        self.url = url
        self.title = title
    }

    var body: some View {
        NavigationStack {
            PDFKitView(url: url)
                .edgesIgnoringSafeArea(.bottom)
                .navigationTitle(title ?? url.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: { dismiss() }) {
                            Text(L10n.Close.key)
                        }
                    }
                }
        }
    }
}

struct IdentifiableURL: Identifiable {
    let url: URL
    let title: String?
    var id: String { url.absoluteString }

    init(url: URL, title: String? = nil) {
        self.url = url
        self.title = title
    }
}

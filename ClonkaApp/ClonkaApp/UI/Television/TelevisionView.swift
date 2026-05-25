import SwiftUI
import WebKit

struct TelevisionView: View {
    let moduleId: Int
    @StateObject private var viewModel: TelevisionViewModel

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: TelevisionViewModel(moduleId: moduleId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                SLoading()
            } else if let error = viewModel.errorMessage {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if viewModel.hasUrl, let url = URL(string: viewModel.detail!.Url!) {
                TelevisionWebView(url: url)
                    .ignoresSafeArea(edges: .bottom)
            } else if viewModel.hasHtml {
                HTMLContentView(html: viewModel.detail!.HtmlContent!)
            } else if viewModel.detail != nil {
                VStack(spacing: 20) {
                    Image(systemName: "tv")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    Text(viewModel.detail?.DisplayName ?? "Television")
                        .font(.title2.bold())
                    Text("No content available")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SEmptyState(icon: "tv", message: "No television content")
            }
        }
        .navigationTitle(viewModel.detail?.DisplayName ?? "Television")
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }
}

private struct TelevisionWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            webView.load(URLRequest(url: url))
        }
    }
}

import SwiftUI
import WebKit

struct CustomPageView: View {
    let moduleId: Int
    @StateObject private var viewModel: CustomPageViewModel

    init(moduleId: Int) {
        self.moduleId = moduleId
        _viewModel = StateObject(wrappedValue: CustomPageViewModel(moduleId: moduleId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                SLoading()
            } else if let error = viewModel.errorMessage {
                SErrorState(message: error) { Task { await viewModel.load() } }
            } else if viewModel.pages.isEmpty {
                SEmptyState(icon: "doc.richtext", message: "No content available")
            } else if viewModel.pages.count == 1, let page = viewModel.pages.first {
                pageContent(page)
                    .navigationTitle(page.DisplayName ?? "Page")
            } else {
                List(viewModel.pages) { page in
                    NavigationLink(destination: pageContent(page).navigationTitle(page.DisplayName ?? "Page")) {
                        HStack {
                            Text(page.DisplayName ?? "Page")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Custom Page")
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private func pageContent(_ page: CustomPage) -> some View {
        if page.hasUrl {
            WebURLContentView(url: URL(string: page.Url!)!)
                .ignoresSafeArea(edges: .bottom)
        } else if page.hasHtml {
            HTMLContentView(html: page.HtmlContent!)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "doc.questionmark")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("This page has no content")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Page ID: \(page.ID ?? 0)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Button("Retry") { Task { await viewModel.load() } }
                    .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct WebURLContentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            webView.load(URLRequest(url: url))
        }
    }
}

import SwiftUI
import WebKit

struct WebURLView: View {
    let url: String?
    let title: String

    var body: some View {
        Group {
            if let urlStr = url, let webURL = URL(string: urlStr) {
                WebURLContentView(url: webURL)
            } else {
                SErrorState(message: "Invalid URL") {}
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
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

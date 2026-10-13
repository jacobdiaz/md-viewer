import AppKit
import SwiftUI
import WebKit

/// Renders Markdown in a WKWebView. The page is self-contained (markdown-it is bundled),
/// so nothing is fetched from the network.
struct MarkdownView: NSViewRepresentable {
    let markdown: String
    let fileURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        guard coordinator.lastMarkdown != markdown || coordinator.lastFileURL != fileURL else { return }
        coordinator.lastMarkdown = markdown
        coordinator.lastFileURL = fileURL

        // Relative links and images resolve against the document's folder.
        let baseURL = fileURL?.deletingLastPathComponent()
        coordinator.baseURL = baseURL
        webView.loadHTMLString(Renderer.html(for: markdown), baseURL: baseURL)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastMarkdown: String?
        var lastFileURL: URL?
        var baseURL: URL?

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // In-page anchors such as [Intro](#intro) stay inside the view.
            if url.fragment != nil, samePage(url) {
                decisionHandler(.allow)
                return
            }

            // Web links go to the browser; local files (including other .md files) go to their default app.
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }

        private func samePage(_ url: URL) -> Bool {
            guard let baseURL else { return false }
            return url.path.trimmingTrailingSlash == baseURL.path.trimmingTrailingSlash
        }
    }
}

private extension String {
    var trimmingTrailingSlash: String {
        var result = self
        while result.count > 1, result.hasSuffix("/") {
            result.removeLast()
        }
        return result
    }
}

enum Renderer {
    private static let template = resource(named: "template", extension: "html")
    private static let markdownIt = resource(named: "markdown-it.min", extension: "js")

    static func html(for markdown: String) -> String {
        template
            .replacingOccurrences(of: "/*__MARKDOWN_IT__*/", with: markdownIt)
            .replacingOccurrences(of: "__MARKDOWN_JSON__", with: jsStringLiteral(markdown))
    }

    /// JSON-encodes the source as a JS string literal. "</" is escaped so the text
    /// cannot close the surrounding <script> element.
    private static func jsStringLiteral(_ text: String) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: [text], options: [])) ?? Data("[\"\"]".utf8)
        let array = String(decoding: data, as: UTF8.self)
        let literal = String(array.dropFirst().dropLast())
        return literal.replacingOccurrences(of: "</", with: "<\\/")
    }

    private static func resource(named name: String, extension ext: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            fatalError("Missing bundled resource \(name).\(ext)")
        }
        return text
    }
}

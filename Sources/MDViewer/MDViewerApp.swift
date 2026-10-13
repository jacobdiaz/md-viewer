import SwiftUI

@main
struct MDViewerApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { configuration in
            MarkdownView(markdown: configuration.document.text, fileURL: configuration.fileURL)
                .frame(minWidth: 480, minHeight: 360)
        }
    }
}

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// Declared in Info.plist as an imported type so Finder maps .md / .markdown to it.
    static let markdown = UTType(importedAs: "net.daringfireball.markdown")
}

/// Read-only document: the viewer never writes back to disk.
struct MarkdownDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.markdown, .plainText]

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteNoPermission)
    }
}

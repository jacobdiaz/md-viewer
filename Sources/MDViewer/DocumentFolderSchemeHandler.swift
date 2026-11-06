import UniformTypeIdentifiers
import WebKit

/// Serves the files a document references, such as images, to the web view.
///
/// This exists so the page's base URL is never a file:// URL. Given one, `loadHTMLString(_:baseURL:)`
/// asks the kernel for read access to the whole folder on the main thread. If that folder is
/// privacy-protected (Downloads, Desktop, Documents), the call blocks until a permission prompt is
/// answered, and the app hangs. Here WebKit asks for nothing, and a file is only read, off the main
/// thread, if the document actually references it.
final class DocumentFolderSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "mdviewer-file"

    /// The only folder files are served from. Main thread only.
    var folder: URL?

    /// Tasks WebKit has not stopped; calling a stopped task raises an exception. Main thread only.
    private var activeTasks = Set<ObjectIdentifier>()

    /// Serial because a read can wait indefinitely on a privacy check. This caps those at one
    /// parked thread per window, however many images a document has.
    private let readQueue = DispatchQueue(label: "dev.jacobdiaz.mdviewer.document-folder", qos: .userInitiated)

    static func baseURL(for folder: URL) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "local"
        components.path = folder.path.hasSuffix("/") ? folder.path : folder.path + "/"
        return components.url
    }

    /// The file a URL in this scheme names, or nil for any other URL.
    static func fileURL(from url: URL) -> URL? {
        guard url.scheme == scheme else { return nil }
        return URL(fileURLWithPath: url.path)
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let requestURL = task.request.url,
              let file = Self.fileURL(from: requestURL),
              let folder
        else {
            task.didFailWithError(CocoaError(.fileNoSuchFile))
            return
        }

        let id = ObjectIdentifier(task)
        activeTasks.insert(id)

        readQueue.async {
            let result = Result { try Self.read(file, within: folder) }

            DispatchQueue.main.async { [self] in
                guard activeTasks.remove(id) != nil else { return }
                switch result {
                case .success(let data):
                    task.didReceive(URLResponse(
                        url: requestURL,
                        mimeType: Self.mimeType(of: file),
                        expectedContentLength: data.count,
                        textEncodingName: nil
                    ))
                    task.didReceive(data)
                    task.didFinish()
                case .failure(let error):
                    task.didFailWithError(error)
                }
            }
        }
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {
        activeTasks.remove(ObjectIdentifier(task))
    }

    /// Resolves symlinks and ".." first, so a document cannot read outside its own folder.
    private static func read(_ file: URL, within folder: URL) throws -> Data {
        let target = file.resolvingSymlinksInPath().path
        let root = folder.resolvingSymlinksInPath().path
        guard target.hasPrefix(root.hasSuffix("/") ? root : root + "/") else {
            throw CocoaError(.fileReadNoPermission)
        }
        return try Data(contentsOf: URL(fileURLWithPath: target))
    }

    private static func mimeType(of file: URL) -> String {
        UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
}

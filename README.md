# MD Viewer

A small, native macOS app for reading Markdown. It renders `.md` and `.markdown` files as a clean, readable page with a table of contents on the right, and follows your system light or dark appearance.

## Install

1. Download `MDViewer-0.1.0.dmg` from the [Releases page](https://github.com/jacobdiaz/md-viewer/releases).
2. Open the DMG and drag **MD Viewer** onto the **Applications** folder.
3. Eject the DMG.

### First launch (unsigned app)

The app is not signed with an Apple Developer ID, so macOS blocks it the first time. Do one of these:

- **Finder:** right-click **MD Viewer** in Applications, choose **Open**, then click **Open** in the dialog.
- **Terminal:** run this once, then open the app normally:

  ```sh
  xattr -dr com.apple.quarantine "/Applications/MD Viewer.app"
  ```

After the first successful launch, macOS remembers the choice.

### Make it the default for Markdown

Right-click any `.md` file, choose **Get Info**, expand **Open with**, pick **MD Viewer**, then click **Change All…**.

## Use

- **Open a file:** double-click a `.md` file, or use **File > Open** (⌘O). Recent files are under **File > Open Recent**.
- **Table of contents:** every heading (`#` through `######`) appears on the right. Click one to jump to it. The section you're reading is highlighted. The panel hides on narrow windows.
- **Links:** web links open in your browser. Links to other local `.md` files open in MD Viewer. In-page `#anchor` links jump within the document.
- **Images:** relative image paths resolve against the folder the Markdown file lives in.
- **Read-only:** the viewer never modifies your files.

## Build from source

Requires macOS 14 or later and Xcode command-line tools (Swift 6 toolchain).

```sh
./scripts/build-app.sh   # build/MDViewer.app
./scripts/build-dmg.sh   # build/MDViewer-0.1.0.dmg
```

`build-app.sh` compiles the release binary, assembles the `.app` bundle, copies the bundled markdown-it renderer and page template, and registers the document types with Launch Services. `build-dmg.sh` runs it and packages the result with an Applications shortcut.

## Project layout

| Path | What it is |
| --- | --- |
| `Sources/MDViewer/` | SwiftUI app: document type, window, WKWebView renderer |
| `Web/template.html` | Page styling, table of contents, and render script |
| `Web/markdown-it.min.js` | Vendored markdown-it 14.1.0 (MIT) |
| `Info.plist` | Bundle metadata and Markdown document-type declarations |
| `Icon/AppIcon.icns` | App icon, generated from `Icon/source.png` |
| `scripts/` | Build scripts for the `.app` and `.dmg` |

## Known limits

- Code blocks are not syntax-highlighted yet.
- The file is read when it opens. Edits on disk need the window closed and reopened.
- The app is ad-hoc signed, not notarized, so it needs the first-launch step above.

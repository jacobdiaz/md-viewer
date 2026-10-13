// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "MDViewer",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MDViewer",
            path: "Sources/MDViewer"
        )
    ]
)

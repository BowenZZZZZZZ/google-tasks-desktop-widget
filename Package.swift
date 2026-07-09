// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GoogleTasksDesktopWidget",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "GoogleTasksDesktopWidget", targets: ["GoogleTasksDesktopWidget"])
    ],
    targets: [
        .executableTarget(
            name: "GoogleTasksDesktopWidget",
            path: "Sources/GoogleTasksDesktopWidget"
        )
    ]
)

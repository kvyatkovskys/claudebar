// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeBar",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0"),
    ],
    targets: [
        .executableTarget(
            name: "ClaudeBar",
            path: "Sources",
            exclude: ["Info.plist", "ClaudeBar.entitlements"],
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        ),
        .testTarget(
            name: "ClaudeBarTests",
            dependencies: ["ClaudeBar", "ViewInspector"],
            path: "Tests"
        ),
    ]
)

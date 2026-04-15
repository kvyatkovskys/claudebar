// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeBar",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ClaudeBar", targets: ["ClaudeBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "ClaudeBarUI",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "ClaudeBar",
            dependencies: ["ClaudeBarUI"],
            exclude: ["Info.plist", "ClaudeBar.entitlements"]
        ),
        .testTarget(
            name: "ClaudeBarTests",
            dependencies: ["ClaudeBarUI", "ViewInspector"],
            path: "Tests"
        ),
    ]
)

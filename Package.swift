// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MetaPeek",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
    ],
    targets: [
        .executableTarget(
            name: "MetaPeek",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)

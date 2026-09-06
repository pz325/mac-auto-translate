// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "mac-auto-translate",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MacAutoTranslateCore", targets: ["MacAutoTranslateCore"]),
        .executable(name: "MacAutoTranslate", targets: ["MacAutoTranslateApp"]),
        .executable(name: "mac-auto-translate-service", targets: ["MacAutoTranslateService"]),
        .executable(name: "mac-auto-translate-mcp", targets: ["MacAutoTranslateMCP"]),
    ],
    targets: [
        .target(name: "MacAutoTranslateCore"),
        .executableTarget(
            name: "MacAutoTranslateApp",
            dependencies: ["MacAutoTranslateCore"]
        ),
        .executableTarget(
            name: "MacAutoTranslateService",
            dependencies: ["MacAutoTranslateCore"]
        ),
        .executableTarget(
            name: "MacAutoTranslateMCP",
            dependencies: ["MacAutoTranslateCore"]
        ),
        .testTarget(
            name: "MacAutoTranslateCoreTests",
            dependencies: ["MacAutoTranslateCore"]
        ),
    ],
    swiftLanguageModes: [.v5]
)

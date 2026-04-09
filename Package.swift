// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftCypher",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(
            name: "SwiftCypher",
            targets: ["SwiftCypher"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.11.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftCypher",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "SwiftCypherTests",
            dependencies: ["SwiftCypher"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

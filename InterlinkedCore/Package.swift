// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Interlinked",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "InterlinkedCore", targets: ["InterlinkedCore"]),
        .library(name: "InterlinkedShared", targets: ["InterlinkedShared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", .upToNextMinor(from: "508.0.0")),
        .package(url: "https://github.com/davecom/SwiftGraph", .upToNextMinor(from: "3.1.0")),
    ],
    targets: [
        .target(name: "InterlinkedShared"),
        .target(
            name: "InterlinkedCore",
            dependencies: [
                .target(name: "InterlinkedShared"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftGraph", package: "SwiftGraph"),
            ]
        ),
        .testTarget(
            name: "InterlinkedCoreTests",
            dependencies: [
                .target(name: "InterlinkedCore"),
                .target(name: "InterlinkedShared"),
            ]
        ),
    ]
)

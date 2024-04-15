// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Interlinked",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "InterlinkedCore", targets: ["InterlinkedCore"]),
        .library(name: "InterlinkedShared", targets: ["InterlinkedShared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", .upToNextMajor(from: "509.0.0")),
        .package(url: "https://github.com/davecom/SwiftGraph", .upToNextMinor(from: "3.1.0")),
    ],
    targets: [
        .target(name: "InterlinkedShared"),
        .target(
            name: "InterlinkedCore",
            dependencies: [
                .target(name: "InterlinkedShared"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
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

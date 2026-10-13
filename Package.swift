// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InstanaAgent",
    platforms: [.iOS(.v12), .macOS(.v10_15)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "InstanaAgent",
            targets: ["InstanaAgent"]),
        .library(
            name: "InstanaSessionReplay",
            targets: ["InstanaSessionReplay"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/1024jp/GzipSwift.git", from: "6.0.1"),
        .package(url: "https://github.com/SDWebImage/SDWebImageWebPCoder.git", from: "0.14.5")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "ImageTracker", dependencies: [], publicHeadersPath: ""),
        .target(
            name: "InstanaAgent",
            dependencies: [
                .product(name: "Gzip", package: "GzipSwift"),
                "ImageTracker"
            ],
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "InstanaAgentTests",
            dependencies: ["InstanaAgent", "ImageTracker"]),
        .target(
            name: "InstanaSessionReplay",
            dependencies: ["InstanaAgent", "ImageTracker",
                           .product(name: "SDWebImageWebPCoder", package: "SDWebImageWebPCoder")],
            path: "SessionReplay/Sources"),
        .testTarget(
            name: "InstanaSessionReplayTests",
            dependencies: ["InstanaSessionReplay",
                           .product(name: "SDWebImageWebPCoder", package: "SDWebImageWebPCoder")],
            path: "SessionReplay/Tests"),
    ]
)

// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DMBIAnalytics",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "DMBIAnalytics",
            targets: ["DMBIAnalytics"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DMBIAnalytics",
            dependencies: [],
            path: "Sources/DMBIAnalytics"),
        .testTarget(
            name: "DMBIAnalyticsTests",
            dependencies: ["DMBIAnalytics"],
            path: "Tests/DMBIAnalyticsTests"),
    ]
)

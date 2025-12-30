// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CapraAnalytics",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "CapraAnalytics",
            targets: ["CapraAnalytics"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CapraAnalytics",
            dependencies: [],
            path: "Sources/CapraAnalytics"),
        .testTarget(
            name: "CapraAnalyticsTests",
            dependencies: ["CapraAnalytics"],
            path: "Tests/CapraAnalyticsTests"),
    ]
)

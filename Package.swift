// swift-tools-version:5.9

import PackageDescription

let targets: [Target] = [
    .target(
        name: "XcodeGraph",
        dependencies: [
            "AnyCodable",
            "Path",
        ],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
        ]
    ),
    .target(
        name: "XcodeProjToGraph",
        dependencies: [
            "XcodeGraph",
            .product(name: "Path", package: "Path"),
            .product(name: "XcodeProj", package: "XcodeProj"),
        ],
        path: "Sources/XcodeProjToGraph"
    ),
    .target(
        name: "TestSupport",
        dependencies: [
            "XcodeProjToGraph",
        ],
        path: "Sources/TestSupport"
    ),
    .testTarget(
        name: "XcodeGraphTests",
        dependencies: [
            "XcodeGraph",
        ],
        path: "Tests/XcodeGraphTests"
    ),
    .testTarget(
        name: "XcodeProjToGraphTests",
        dependencies: [
            "XcodeProjToGraph",
            "TestSupport"
        ],
        path: "Tests/XcodeProjToGraphTests"
    ),
]

let package = Package(
    name: "XcodeGraph",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "XcodeGraph",
            targets: ["XcodeGraph"]
        ),
        .library(name: "XcodeProjToGraph", targets: ["XcodeProjToGraph"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMajor(from: "0.6.7")),
        .package(url: "https://github.com/tuist/Path.git", .upToNextMajor(from: "0.3.8")),
        .package(url: "https://github.com/tuist/XcodeProj", .upToNextMajor(from: "8.25.0"))
    ],
    targets: targets
)

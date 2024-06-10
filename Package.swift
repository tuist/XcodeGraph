// swift-tools-version:5.9

import PackageDescription

var targets: [Target] = [
    .target(
        name: "XcodeGraph",
        dependencies: [
            "AnyCodable",
            "Path",
        ]
    )
]

let package = Package(
    name: "XcodeGraph",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "XcodeGraph",
            targets: ["XcodeGraph"]
        ),
        .library(
            name: "XcodeGraphTesting",
            targets: ["XcodeGraphTesting"]
        ),

    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMajor(from: "0.6.7")),
        .package(url: "https://github.com/tuist/Path.git", .upToNextMajor(from: "0.3.0")),
    ],
    targets: targets
)

// swift-tools-version:5.9

import PackageDescription

var targets: [Target] = [
    .target(
        name: "XcodeGraph",
        dependencies: [
            "AnyCodable",
            "Mockable",
            "Path",
        ],
        swiftSettings: [
            .define("MOCKING", .when(configuration: .debug)),
        ]
    ),
    .target(
        name: "XcodeGraphTesting",
        dependencies: [
            "XcodeGraph",
            "AnyCodable",
        ],
        linkerSettings: [.linkedFramework("XCTest")]
    ),
]

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "Mockable": .staticFramework,
            "MockableTest": .staticFramework,
        ]
    )

#endif

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
        .package(url: "https://github.com/Kolos65/Mockable.git", .upToNextMajor(from: "0.0.8")),
        .package(url: "https://github.com/tuist/Path.git", .upToNextMajor(from: "0.2.0")),
    ],
    targets: targets
)

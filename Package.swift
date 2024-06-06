// swift-tools-version:5.10

import PackageDescription

var targets: [Target] = [
    .target(
        name: "XcodeGraph",
        dependencies: [
            "AnyCodable",
            "Mockable",
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
    )
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
    name: "tuist",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "XcodeGraph",
            targets: ["XcodeGraph"]
        ),
        .library(
            name: "XcodeGraphTesting",
            targets: ["XcodeGraphTesting"]
        )

    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.7"),
        .package(url: "https://github.com/Kolos65/Mockable.git", from: "0.0.2"),
    ],
    targets: targets
)

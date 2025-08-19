// swift-tools-version:5.10
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
        name: "XcodeMetadata",
        dependencies: [
            .product(name: "FileSystem", package: "FileSystem"),
            .product(name: "Mockable", package: "Mockable"),
            .product(name: "MachOKitC", package: "MachOKit"),
            "XcodeGraph",
        ],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
            .define("MOCKING", .when(configuration: .debug)),
        ]
    ),
    .testTarget(
        name: "XcodeMetadataTests",
        dependencies: ["XcodeMetadata", "XcodeGraph"],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
        ]
    ),
    .target(
        name: "XcodeGraphMapper",
        dependencies: [
            "XcodeGraph",
            "XcodeMetadata",
            .product(name: "Command", package: "Command"),
            .product(name: "Path", package: "Path"),
            .product(name: "XcodeProj", package: "XcodeProj"),
        ],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
            .define("MOCKING", .when(configuration: .debug)),
        ]
    ),
    .testTarget(
        name: "XcodeGraphTests",
        dependencies: [.target(name: "XcodeGraph")],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
        ]
    ),
    .testTarget(
        name: "XcodeGraphMapperTests",
        dependencies: [
            "XcodeGraphMapper",
            .product(name: "FileSystem", package: "FileSystem"),
        ],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
            .define("MOCKING", .when(configuration: .debug)),
        ]
    ),
]

let package = Package(
    name: "XcodeGraph",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "XcodeGraph",
            targets: ["XcodeGraph"]
        ),
        .library(name: "XcodeMetadata", targets: ["XcodeMetadata"]),
        .library(name: "XcodeGraphMapper", targets: ["XcodeGraphMapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMajor(from: "0.6.7")),
        .package(url: "https://github.com/tuist/Path.git", .upToNextMajor(from: "0.3.8")),
        .package(url: "https://github.com/tuist/XcodeProj", .upToNextMajor(from: "9.5.0")),
        .package(url: "https://github.com/tuist/Command.git", from: "0.13.0"),
        .package(url: "https://github.com/tuist/FileSystem.git", .upToNextMajor(from: "0.11.10")),
        .package(url: "https://github.com/Kolos65/Mockable.git", .upToNextMajor(from: "0.4.0")),
        .package(url: "https://github.com/p-x9/MachOKit", .upToNextMajor(from: "0.38.0")),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.5"),
    ],
    targets: targets
)

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
        name: "MetadataProviders",
        dependencies: [
            .product(name: "ServiceContextModule", package: "swift-service-context"),
            .product(name: "FileSystem", package: "FileSystem"),
            .product(name: "Mockable", package: "Mockable"),
        ],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
            .define("MOCKING", .when(configuration: .debug)),
        ]
    ),
    .target(
        name: "XcodeProjMapper",
        dependencies: [
            "XcodeGraph",
            "MetadataProviders",
            .product(name: "Command", package: "Command"),
            .product(name: "Path", package: "Path"),
            .product(name: "XcodeProj", package: "XcodeProj"),
        ],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
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
        name: "XcodeProjMapperTests",
        dependencies: [
            "XcodeProjMapper",
            .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
        ],
        resources: [
            .copy("Resources"),
        ],
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
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
        .library(name: "XcodeProjMapper", targets: ["XcodeProjMapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMajor(from: "0.6.7")),
        .package(url: "https://github.com/tuist/Path.git", .upToNextMajor(from: "0.3.8")),
        .package(url: "https://github.com/tuist/XcodeProj", from: "8.26.0"),
        .package(url: "https://github.com/tuist/Command.git", from: "0.11.0"),
        .package(url: "https://github.com/tuist/FileSystem.git", .upToNextMajor(from: "0.6.17")),
        .package(url: "https://github.com/apple/swift-service-context", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/Kolos65/Mockable.git", .upToNextMajor(from: "0.0.11")),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.17.0"
        ),
    ],

    targets: targets
)

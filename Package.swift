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
        name: "XcodeProjMapper",
        dependencies: [
            "XcodeGraph",
            .product(name: "Path", package: "Path"),
            .product(name: "XcodeProj", package: "XcodeProj"),
        ],
        path: "Sources/XcodeProjMapper",
        swiftSettings: [
            .enableExperimentalFeature("StrictConcurrency"),
        ]
    ),
    .testTarget(
        name: "XcodeGraphTests",
        dependencies: [
            "XcodeGraph",
        ],
        path: "Tests/XcodeGraphTests"
    ),
    .testTarget(
        name: "XcodeProjMapperTests",
        dependencies: [
            "XcodeProjMapper",
            .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
        ],
        path: "Tests/XcodeProjMapperTests",
        resources: [
            .copy("Resources"),
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
        .package(url: "https://github.com/tuist/XcodeProj", from: "8.25.0"),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.17.0"
        ),
    ],

    targets: targets
)

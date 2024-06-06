import ProjectDescription

let config = Config(
    cloud: .cloud(
        projectId: "tuist/xcodegraph",
        url: "https://cloud.tuist.io",
        options: [.optional]
    ),
    swiftVersion: .init("5.9")
)

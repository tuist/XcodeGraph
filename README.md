# ፨ XcodeGraph

XcodeGraph is a Swift Package that contains data structures to model an Xcode projects graph.
It was initially developed as part of [Tuist](https://github.com/tuist/tuist) and extracted to be Tuist-agnostic.

> [!NOTE]
> We extracted the graph data structures from Tuist to commoditize them and make them available to other projects that might need to model and generate Xcode projects.

## Installation

To install `XcodeGraph`, you can add it to your project or package's `Package.swift`:

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeGraph.git", .upToNextMajor(from: "0.1.0")),
    ],
)
```
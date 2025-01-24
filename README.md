# ፨ XcodeGraph
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-6-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

XcodeGraph is a Swift Package that contains data structures to model an Xcode projects graph.
It was initially developed as part of [Tuist](https://github.com/tuist/tuist) and extracted to be Tuist-agnostic.

> [!NOTE]
> We extracted the graph data structures from Tuist to commoditize them and make them available to other projects that might need to model and generate Xcode projects.

## Installation

To install `XcodeGraph`, you can add it to your project or package's `Package.swift`:

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeGraph.git", .upToNextMajor(from: "0.7.0")),
    ],
)
```

## XcodeGraphMapper

XcodeGraphMapper parses `.xcworkspace` or `.xcodeproj` files using `XcodeProj` and constructs a `XcodeGraph.Graph` representing their projects, targets, and dependencies:

### Usage

```swift
import XcodeGraphMapper
let mapper: XcodeGraphMapping = XcodeGraphMapper()
let path = try AbsolutePath(validating: "/path/to/MyProjectOrWorkspace")
let graph = try await mapper.map(at: path)
// You now have a Graph containing projects, targets, packages, and dependencies.*
// Example: print all target names across all projects*
for project in graph.projects.values {
    for (targetName, _) in project.targets {
        print("Found target: \(targetName)")
    }
}
```

Once you have the Graph, you can explore or transform it as needed—printing targets, analyzing dependencies, generating reports, or integrating into other build tools.

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="http://darrarski.pl"><img src="https://avatars.githubusercontent.com/u/1384684?v=4?s=100" width="100px;" alt="Dariusz Rybicki"/><br /><sub><b>Dariusz Rybicki</b></sub></a><br /><a href="https://github.com/tuist/XcodeGraph/commits?author=darrarski" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Binlogo"><img src="https://avatars.githubusercontent.com/u/7845507?v=4?s=100" width="100px;" alt="Binlogo"/><br /><sub><b>Binlogo</b></sub></a><br /><a href="https://github.com/tuist/XcodeGraph/commits?author=Binlogo" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/filipracki"><img src="https://avatars.githubusercontent.com/u/27164368?v=4?s=100" width="100px;" alt="Filip Racki"/><br /><sub><b>Filip Racki</b></sub></a><br /><a href="https://github.com/tuist/XcodeGraph/commits?author=filipracki" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/rgnns"><img src="https://avatars.githubusercontent.com/u/811827?v=4?s=100" width="100px;" alt="Gabriel Liévano"/><br /><sub><b>Gabriel Liévano</b></sub></a><br /><a href="https://github.com/tuist/XcodeGraph/commits?author=rgnns" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/fila95"><img src="https://avatars.githubusercontent.com/u/7265334?v=4?s=100" width="100px;" alt="Giovanni Filaferro"/><br /><sub><b>Giovanni Filaferro</b></sub></a><br /><a href="https://github.com/tuist/XcodeGraph/commits?author=fila95" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Garfeild"><img src="https://avatars.githubusercontent.com/u/12799?v=4?s=100" width="100px;" alt="Anton Kolchunov"/><br /><sub><b>Anton Kolchunov</b></sub></a><br /><a href="https://github.com/tuist/XcodeGraph/commits?author=Garfeild" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!

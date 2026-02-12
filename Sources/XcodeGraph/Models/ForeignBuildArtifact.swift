import Path

public enum ForeignBuildArtifact: Equatable, Hashable, Codable, Sendable {
    case xcframework(path: AbsolutePath, linking: BinaryLinking)
    case framework(path: AbsolutePath, linking: BinaryLinking)
    case library(path: AbsolutePath, publicHeaders: AbsolutePath, swiftModuleMap: AbsolutePath?, linking: BinaryLinking)

    public var path: AbsolutePath {
        switch self {
        case let .xcframework(path, _): return path
        case let .framework(path, _): return path
        case let .library(path, _, _, _): return path
        }
    }

    public var linking: BinaryLinking {
        switch self {
        case let .xcframework(_, linking): return linking
        case let .framework(_, linking): return linking
        case let .library(_, _, _, linking): return linking
        }
    }
}

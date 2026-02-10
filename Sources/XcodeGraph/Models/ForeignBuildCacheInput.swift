import Path

public enum ForeignBuildCacheInput: Equatable, Hashable, Codable, Sendable {
    case file(AbsolutePath)
    case folder(AbsolutePath)
    case glob(String)
    case script(String)
}

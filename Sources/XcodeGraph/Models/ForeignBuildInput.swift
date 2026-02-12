import Path

public enum ForeignBuildInput: Equatable, Hashable, Codable, Sendable {
    case file(AbsolutePath)
    case folder(AbsolutePath)
    case script(String)
}

import Foundation
import Path

public enum Package: Equatable, Codable, Sendable {
    case remote(url: String, requirement: Requirement)
    /// Parameters
    ///  - path: Absolute path of a package
    ///  - groupPath: Path which would be used to
    ///  structure packages in generated project
    case local(path: AbsolutePath, groupPath: String?)
}

extension XcodeGraph.Package {
    public var isRemote: Bool {
        switch self {
        case .remote:
            return true
        case .local:
            return false
        }
    }
}

import Foundation
import Path

public enum Package: Equatable, Codable, Sendable {
    case remote(url: String, requirement: Requirement)
    /// Parameters
    ///  - path: Absolute path of a package
    ///  - groupPath: Path which would be used to
    ///  structure packages in generated project
    case local(config: LocalPackageReferenceConfig)
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

public struct LocalPackageReferenceConfig: Equatable, Codable, Sendable {
    public let path: AbsolutePath
    public let groupPath: String?
    public let excludingPath: String?
    public let keepStructure: Bool

    public var isStandardReference: Bool {
        groupPath == nil &&
        excludingPath == nil &&
        keepStructure == false
    }
    
    public init(
        path: AbsolutePath,
        groupPath: String? = nil,
        excludingPath: String? = nil,
        keepStructure: Bool = false
    ) {
        self.path = path
        self.groupPath = groupPath
        self.excludingPath = excludingPath
        self.keepStructure = keepStructure
    }
}

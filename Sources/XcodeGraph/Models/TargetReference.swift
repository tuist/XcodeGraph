import Foundation
import Path

public struct TargetReference: Hashable, Codable, Sendable {
    public var projectPath: AbsolutePath
    public var name: String

    public init(projectPath: AbsolutePath, name: String) {
        self.projectPath = projectPath
        self.name = name
    }
}

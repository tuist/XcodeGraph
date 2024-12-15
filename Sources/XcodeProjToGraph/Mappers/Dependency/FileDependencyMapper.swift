import Path
import XcodeGraph
import XcodeProj

/// A helper responsible for mapping file-based dependencies (like frameworks or libraries) into `TargetDependency` models.
final class FileDependencyMapper: Sendable {
    private let projectProvider: ProjectProviding

    init(projectProvider: ProjectProviding) {
        self.projectProvider = projectProvider
    }

    public func mapDependency(pathString: String?, condition: PlatformCondition?) async throws
        -> TargetDependency?
    {
        guard let pathString else { return nil }
        let validatedPath = projectProvider.sourceDirectory.appending(
            try RelativePath(validating: pathString)
        )
        let absPath = try AbsolutePath.resolvePath(validatedPath.pathString)
        return absPath.mapByExtension(condition: condition)
    }
}

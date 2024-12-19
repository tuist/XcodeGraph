import Foundation
import Path
import XcodeGraph
import XcodeProj

/// A protocol that defines how to map a single `PBXTargetDependency` into a `TargetDependency` model.
///
/// Implementations of this protocol handle all known dependency types—direct targets, package products,
/// proxy references (which may point to other targets or projects), and file-based dependencies.
protocol DependencyMapping {
    /// Maps a single `PBXTargetDependency` into a `TargetDependency` model.
    ///
    /// - Parameters:
    ///   - dependency: The `PBXTargetDependency` to map.
    ///   - projectProvider: Provides access to the project's `.xcodeproj` and source directory.
    /// - Returns: A `TargetDependency` model if the dependency can be resolved; otherwise, `nil`.
    /// - Throws: If the dependency references invalid paths or targets that cannot be resolved.
    func map(_ dependency: PBXTargetDependency, projectProvider: ProjectProviding) throws -> TargetDependency?
}

/// A unified mapper that handles all types of `PBXTargetDependency` instances.
///
/// `PBXTargetDependencyMapper` checks if the dependency references a direct target, a package product,
/// or a proxy. For proxy dependencies, it may resolve references to another target, a project,
/// or file-based dependencies (frameworks, libraries, etc.). If a dependency cannot be resolved
/// to a known domain model, it returns `nil`.
struct PBXTargetDependencyMapper: DependencyMapping {
    func map(_ dependency: PBXTargetDependency, projectProvider: ProjectProviding) throws -> TargetDependency? {
        let condition = dependency.platformCondition()

        // 1. Direct target dependency
        if let target = dependency.target {
            return .target(name: target.name, status: .required, condition: condition)
        }

        // 2. Package product dependency
        if let product = dependency.product {
            return .package(
                product: product.productName,
                type: .runtime,
                condition: condition
            )
        }

        // 3. Proxy dependency
        if let targetProxy = dependency.targetProxy, let proxyType = targetProxy.proxyType {
            switch proxyType {
            case .nativeTarget:
                return try mapNativeTargetProxy(targetProxy, condition: condition, projectProvider: projectProvider)
            case .reference:
                return try mapReferenceProxy(targetProxy, condition: condition, projectProvider: projectProvider)
            default:
                return nil
            }
        }

        return nil
    }

    // MARK: - Private Helpers

    private func mapNativeTargetProxy(
        _ targetProxy: PBXContainerItemProxy,
        condition: PlatformCondition?,
        projectProvider: ProjectProviding
    ) throws -> TargetDependency? {
        guard let remoteInfo = targetProxy.remoteInfo else { return nil }

        switch targetProxy.containerPortal {
        case .project:
            // Direct reference to another target in the same project.
            return .target(name: remoteInfo, status: .required, condition: condition)
        case let .fileReference(fileReference):
            guard let projectRelativePath = fileReference.path else { return nil }
            let fullPath = projectProvider.sourceDirectory.pathString + projectRelativePath
            let absPath = try AbsolutePath(validating: fullPath)
            // Reference to a target in another project.
            return .project(target: remoteInfo, path: absPath, status: .required, condition: condition)
        case .unknownObject:
            return nil
        }
    }

    private func mapReferenceProxy(
        _ targetProxy: PBXContainerItemProxy,
        condition: PlatformCondition?,
        projectProvider: ProjectProviding
    ) throws -> TargetDependency? {
        guard let remoteGlobalID = targetProxy.remoteGlobalID else { return nil }

        switch remoteGlobalID {
        case let .object(object):
            if let fileReference = object as? PBXFileReference {
                return try mapFileDependency(
                    pathString: fileReference.path,
                    condition: condition,
                    projectProvider: projectProvider
                )
            } else if let referenceProxy = object as? PBXReferenceProxy {
                return try mapFileDependency(
                    pathString: referenceProxy.path,
                    condition: condition,
                    projectProvider: projectProvider
                )
            }
            return nil
        case .string:
            return nil
        }
    }

    /// Maps file-based dependencies (e.g., frameworks, libraries) into `TargetDependency` models.
    ///
    /// - Parameters:
    ///   - pathString: The path string for the file-based dependency.
    ///   - condition: An optional platform condition.
    ///   - projectProvider: Provides directory structure for resolving relative paths.
    /// - Returns: A `TargetDependency` if the file’s extension matches a known dependency type, or `nil` if not.
    private func mapFileDependency(
        pathString: String?,
        condition: PlatformCondition?,
        projectProvider: ProjectProviding
    ) throws -> TargetDependency? {
        guard let pathString else { return nil }
        let validatedPath = projectProvider.sourceDirectory.appending(try RelativePath(validating: pathString))
        let absPath = try AbsolutePath(validating: validatedPath.pathString)
        return absPath.mapByExtension(condition: condition)
    }
}

import Foundation
import Path
import XcodeGraph
@preconcurrency import XcodeProj

/// A protocol that defines how to map `PBXTargetDependency` instances into `TargetDependency` domain models.
///
/// Conforming types resolve various dependency references—such as direct targets, packages, or proxy references—
/// and translate them into a consistent `TargetDependency` representation. This enables downstream operations
/// like graph analysis, code generation, or dependency visualization to work from a uniform model of dependencies.
protocol DependencyMapping: Sendable {
    /// Maps all dependencies of a given `PBXTarget` into an array of `TargetDependency` models.
    ///
    /// - Parameter target: The `PBXTarget` whose dependencies are to be mapped.
    /// - Returns: An array of `TargetDependency` models representing the target's dependencies.
    /// - Throws: If any dependency cannot be resolved or mapped correctly.
    func mapDependencies(target: PBXTarget) async throws -> [TargetDependency]
}

/// A protocol that defines how to map a single `PBXTargetDependency` into a `TargetDependency` model.
///
/// Different implementations may specialize in certain types of dependencies (e.g., direct targets, package products,
/// or proxy references). The `DependencyMapper` uses multiple `DependencyTypeMapper` instances in sequence to attempt
/// resolving each dependency.
protocol DependencyTypeMapper: Sendable {
    /// Maps a single `PBXTargetDependency` into a `TargetDependency` model.
    ///
    /// - Parameter dependency: The `PBXTargetDependency` to map.
    /// - Returns: A `TargetDependency` model if the dependency can be resolved by this mapper, or `nil` if not.
    /// - Throws: If mapping fails due to issues like invalid paths or missing targets.
    func mapDependency(_ dependency: PBXTargetDependency) async throws -> TargetDependency?
}

/// A mapper that orchestrates the mapping of all target dependencies using multiple specialized mappers.
///
/// `DependencyMapper` tries each registered `DependencyTypeMapper` in turn until it finds one that can map a given
/// `PBXTargetDependency`. This design supports adding new dependency types without modifying a single large mapping function.
///
/// **Example Usage:**
/// ```swift
/// // Assume you have a ProjectProvider instance for your Xcode project:
/// let projectProvider: ProjectProviding = ...
///
/// // Create a DependencyMapper to handle dependencies in a target.
/// let dependencyMapper = DependencyMapper(projectProvider: projectProvider)
///
/// // Retrieve a PBXTarget from your XcodeProj:
/// let pbxTarget: PBXTarget = ...
///
/// // Map all dependencies of the PBXTarget into TargetDependency models:
/// let targetDependencies = try await dependencyMapper.mapDependencies(target: pbxTarget)
///
/// // 'targetDependencies' now contains a uniform list of dependencies (targets, packages, frameworks, etc.)
/// // which can be analyzed, transformed, or used for code generation.
/// ```
///
/// This straightforward integration lets you focus on what to do with the resolved dependencies,
/// rather than the nuances of resolving them from Xcode's project structure.
public final class DependencyMapper: DependencyMapping {
    private let projectProvider: ProjectProviding
    private let typeMappers: [DependencyTypeMapper]

    /// Creates a new `DependencyMapper` with a given project provider.
    ///
    /// - Parameter projectProvider: Provides access to the project's directories, files, and parsed structures.
    init(projectProvider: ProjectProviding) {
        self.projectProvider = projectProvider
        typeMappers = [
            DirectTargetMapper(),
            PackageProductMapper(),
            ProxyDependencyMapper(projectProvider: projectProvider),
        ]
    }

    public func mapDependencies(target: PBXTarget) async throws -> [TargetDependency] {
        return try await target.dependencies.asyncCompactMap { [typeMappers] dependency in
            for mapper in typeMappers {
                if let mapped = try await mapper.mapDependency(dependency) {
                    return mapped
                }
            }
            return nil
        }
    }
}

/// A mapper that handles direct target dependencies, translating them into `.target` `TargetDependency` models.
final class DirectTargetMapper: DependencyTypeMapper {
    public func mapDependency(_ dependency: PBXTargetDependency) async throws -> TargetDependency? {
        guard let target = dependency.target else { return nil }
        let condition = PlatformConditionMapper.mapCondition(dependency: dependency)
        return .target(name: target.name, status: .required, condition: condition)
    }
}

/// A mapper that handles package product dependencies, converting them into `.package` `TargetDependency` models.
final class PackageProductMapper: DependencyTypeMapper {
    public func mapDependency(_ dependency: PBXTargetDependency) async throws -> TargetDependency? {
        guard let product = dependency.product else { return nil }
        let condition = PlatformConditionMapper.mapCondition(dependency: dependency)
        return .package(
            product: product.productName,
            type: .runtime,
            condition: condition
        )
    }
}

/// A mapper that resolves proxy dependencies, which may point to native targets in other projects or file references.
///
/// Depending on the proxy type, this mapper may return a `.target` or `.project` dependency, or file-based dependencies.
final class ProxyDependencyMapper: DependencyTypeMapper {
    private let projectProvider: ProjectProviding
    private let fileMapper: FileDependencyMapper

    init(projectProvider: ProjectProviding) {
        self.projectProvider = projectProvider
        fileMapper = FileDependencyMapper(projectProvider: projectProvider)
    }

    public func mapDependency(_ dependency: PBXTargetDependency) async throws -> TargetDependency? {
        guard let targetProxy = dependency.targetProxy,
              let proxyType = targetProxy.proxyType
        else { return nil }

        let condition = PlatformConditionMapper.mapCondition(dependency: dependency)

        switch proxyType {
        case .nativeTarget:
            return try await mapNativeTargetProxy(targetProxy, condition: condition)
        case .reference:
            return try await mapReferenceProxy(targetProxy, condition: condition)
        default:
            return nil
        }
    }

    private func mapNativeTargetProxy(
        _ targetProxy: PBXContainerItemProxy,
        condition: PlatformCondition?
    ) async throws -> TargetDependency? {
        guard let remoteInfo = targetProxy.remoteInfo else { return nil }

        switch targetProxy.containerPortal {
        case .project:
            return .target(name: remoteInfo, status: .required, condition: condition)
        case let .fileReference(fileReference):
            guard let projectRelativePath = fileReference.path else { return nil }
            let fullPath = projectProvider.sourceDirectory.pathString + projectRelativePath
            let absPath = try AbsolutePath.resolvePath(fullPath)
            return .project(
                target: remoteInfo,
                path: absPath,
                status: .required,
                condition: condition
            )
        case .unknownObject:
            return nil
        }
    }

    private func mapReferenceProxy(
        _ targetProxy: PBXContainerItemProxy,
        condition: PlatformCondition?
    ) async throws -> TargetDependency? {
        guard let remoteGlobalID = targetProxy.remoteGlobalID else { return nil }

        switch remoteGlobalID {
        case let .object(object):
            if let fileReference = object as? PBXFileReference {
                // If `fileMapper.mapDependency` returns nil, it means this file type
                // doesn't map to a known `TargetDependency` (e.g., unsupported extension).
                return try await fileMapper.mapDependency(
                    pathString: fileReference.path,
                    condition: condition
                )
            } else if let referenceProxy = object as? PBXReferenceProxy {
                // Similarly, nil here indicates that the referenced file isn't a supported dependency type.
                return try await fileMapper.mapDependency(
                    pathString: referenceProxy.path,
                    condition: condition
                )
            }
            return nil
        case .string:
            return nil
        }
    }
}

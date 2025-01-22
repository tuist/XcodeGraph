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
    func map(_ dependency: PBXTargetDependency, xcodeProj: XcodeProj) throws -> TargetDependency
}

/// A unified mapper that handles all types of `PBXTargetDependency` instances.
///
/// `PBXTargetDependencyMapper` checks if the dependency references a direct target, a package product,
/// or a proxy. For proxy dependencies, it may resolve references to another target, a project,
/// or file-based dependencies (frameworks, libraries, etc.). If a dependency cannot be resolved
/// to a known domain model, it returns `nil`.
struct PBXTargetDependencyMapper: DependencyMapping {
    private let pathMapper: PathDependencyMapping

    init(pathMapper: PathDependencyMapping = PathDependencyMapper()) {
        self.pathMapper = pathMapper
    }

    func map(_ dependency: PBXTargetDependency, xcodeProj: XcodeProj) throws -> TargetDependency {
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
        if let targetProxy = dependency.targetProxy {
            switch targetProxy.proxyType {
            case .nativeTarget:
                return try mapNativeTargetProxy(targetProxy, condition: condition, xcodeProj: xcodeProj)
            case .reference:
                return try mapReferenceProxy(targetProxy, condition: condition, xcodeProj: xcodeProj)
            case .other, .none:
                throw TargetDependencyMappingError.unsupportedProxyType(dependency.name)
            }
        }

        throw TargetDependencyMappingError.unknownDependencyType(
            name: dependency.name ?? "Unknown dependency name"
        )
    }

    // MARK: - Private Helpers

    private func mapNativeTargetProxy(
        _ targetProxy: PBXContainerItemProxy,
        condition: PlatformCondition?,
        xcodeProj: XcodeProj
    ) throws -> TargetDependency {
        let remoteInfo = try targetProxy.remoteInfo.throwing(
            TargetDependencyMappingError.missingRemoteInfoInNativeProxy
        )

        switch targetProxy.containerPortal {
        case .project:
            // Direct reference to another target in the same project.
            return .target(name: remoteInfo, status: .required, condition: condition)
        case let .fileReference(fileReference):
            let projectRelativePath = try fileReference.path
                .throwing(TargetDependencyMappingError.missingFileReference(fileReference.name ?? ""))

            let path = xcodeProj.srcPath.appending(component: projectRelativePath)
            // Reference to a target in another project.
            return .project(target: remoteInfo, path: path, status: .required, condition: condition)
        case let .unknownObject(object):
            throw TargetDependencyMappingError.unknownObject(object.debugDescription)
        }
    }

    private func mapReferenceProxy(
        _ targetProxy: PBXContainerItemProxy,
        condition: PlatformCondition?,
        xcodeProj: XcodeProj
    ) throws -> TargetDependency {
        let remoteGlobalID = try targetProxy.remoteGlobalID.throwing(
            TargetDependencyMappingError.missingRemoteGlobalIDInReferenceProxy
        )

        switch remoteGlobalID {
        case let .object(object):
            if let fileReference = object as? PBXFileReference {
                return try mapFileDependency(
                    pathString: fileReference.path,
                    condition: condition,
                    xcodeProj: xcodeProj
                )
            } else if let referenceProxy = object as? PBXReferenceProxy {
                return try mapFileDependency(
                    pathString: referenceProxy.path,
                    condition: condition,
                    xcodeProj: xcodeProj
                )
            }
            throw TargetDependencyMappingError.unknownObject("\(object)")

        case .string:
            // If remoteGlobalID is just a string, we can’t resolve a file-based dependency or target from it.
            throw TargetDependencyMappingError.unknownDependencyType(
                name: "remoteGlobalID is a string, cannot map a known target or file reference."
            )
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
        xcodeProj: XcodeProj
    ) throws -> TargetDependency {
        let pathString = try pathString.throwing(
            TargetDependencyMappingError.missingFileReference("Path string is nil in file dependency.")
        )
        let path = xcodeProj.srcPath.appending(try RelativePath(validating: pathString))
        return try pathMapper.map(path: path, condition: condition)
    }
}

/// Errors that may occur when mapping `TargetDependency` instances into `GraphDependency` models.
enum TargetDependencyMappingError: LocalizedError, Equatable {
    case targetNotFound(targetName: String, path: AbsolutePath)
    case unknownDependencyType(name: String)
    case missingFileReference(String)
    case unknownObject(String)
    case missingRemoteInfoInNativeProxy
    case missingRemoteGlobalIDInReferenceProxy
    case unsupportedProxyType(String?)

    var errorDescription: String? {
        switch self {
        case let .targetNotFound(targetName, path):
            return "The target '\(targetName)' could not be found in the project at: \(path.pathString)."
        case let .unknownDependencyType(name):
            return "An unknown dependency type '\(name)' was encountered."
        case let .missingFileReference(description):
            return "File reference path is missing in target dependency: \(description)."
        case let .unknownObject(description):
            return "Encountered an unknown PBXObject in target dependency: \(description)."
        case .missingRemoteInfoInNativeProxy:
            return "A native target proxy is missing `remoteInfo` in target dependency."
        case .missingRemoteGlobalIDInReferenceProxy:
            return "A reference proxy is missing `remoteGlobalID` in target dependency."
        case let .unsupportedProxyType(name):
            return "Encountered an unsupported PBXProxyType in dependenncy: \(name ?? "Unknown")."
        }
    }
}

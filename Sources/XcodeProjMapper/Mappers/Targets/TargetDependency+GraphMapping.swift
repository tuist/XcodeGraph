import Foundation
import Path
import XcodeGraph
import XcodeMetadata
import XcodeProj

// swiftlint:disable function_body_length
extension TargetDependency {
    /// Maps this `TargetDependency` to a `GraphDependency` by resolving paths, product types,
    /// and linking details. Project-based dependencies are resolved using `allTargetsMap`.
    ///
    /// - Parameters:
    ///   - sourceDirectory: The root directory for resolving relative paths.
    ///   - allTargetsMap: A map of target names to `Target` models for resolving project-based dependencies.
    ///   - target: The target of this dependency.
    ///   - xcframeworkMetadataProvider: Provides metadata (linking, architectures, etc.) for `.xcframework` dependencies.
    ///   - libraryMetadataProvider: Provides metadata for libraries.
    ///   - frameworkMetadataProvider: Provides metadata for frameworks.
    ///   - systemFrameworkMetadataProvider: Provides metadata for system frameworks.
    ///   - developerDirectoryProvider: Provides xcode developer directory.
    /// - Returns: A corresponding `GraphDependency` model for this dependency.
    /// - Throws: `TargetDependencyMappingError` if a referenced target is not found or if the dependency type is unknown.
    func graphDependency(
        sourceDirectory: AbsolutePath,
        allTargetsMap: [String: Target],
        target: Target,
        xcframeworkMetadataProvider: XCFrameworkMetadataProviding = XCFrameworkMetadataProvider(),
        libraryMetadataProvider: LibraryMetadataProviding = LibraryMetadataProvider(),
        frameworkMetadataProvider: FrameworkMetadataProviding = FrameworkMetadataProvider(),
        systemFrameworkMetadataProvider: SystemFrameworkMetadataProviding = SystemFrameworkMetadataProvider(),
        developerDirectoryProvider: DeveloperDirectoryProviding = DeveloperDirectoryProvider()
    ) async throws -> GraphDependency {
        switch self {
        // MARK: - Simple Cases

        case let .target(name, status, _):
            return .target(name: name, path: sourceDirectory, status: status)

        case let .project(targetName, projectPath, status, _):
            return try mapProjectGraphDependency(
                projectPath: projectPath,
                targetName: targetName,
                status: status,
                allTargetsMap: allTargetsMap
            )

        // MARK: - Precompiled Binary Cases

        case let .framework(path, status, _):
            let metadata = try await frameworkMetadataProvider.loadMetadata(at: path, status: status)
            return .framework(
                path: path,
                binaryPath: metadata.binaryPath,
                dsymPath: metadata.dsymPath,
                bcsymbolmapPaths: metadata.bcsymbolmapPaths,
                linking: metadata.linking,
                architectures: metadata.architectures,
                status: status
            )

        case let .xcframework(path, status, _):
            let metadata = try await xcframeworkMetadataProvider.loadMetadata(at: path, status: status)
            return .xcframework(
                .init(
                    path: path,
                    infoPlist: metadata.infoPlist,
                    linking: metadata.linking,
                    mergeable: metadata.mergeable,
                    status: status,
                    macroPath: metadata.macroPath,
                    swiftModules: metadata.swiftModules,
                    moduleMaps: metadata.moduleMaps
                )
            )

        case let .library(path, publicHeaders, swiftModuleMap, _):
            let metadata = try await libraryMetadataProvider.loadMetadata(
                at: path,
                publicHeaders: publicHeaders,
                swiftModuleMap: swiftModuleMap
            )
            return .library(
                path: path,
                publicHeaders: publicHeaders,
                linking: metadata.linking,
                architectures: metadata.architectures,
                swiftModuleMap: swiftModuleMap
            )

        // MARK: - Package & SDK

        case let .package(product, type, _):
            return .packageProduct(
                path: sourceDirectory,
                product: product,
                type: type.graphPackageType
            )

        case let .sdk(name, status, _):
            return .sdk(
                name: name,
                path: sourceDirectory,
                status: status,
                source: .developer
            )

        // MARK: - XCTest (System Provided)

        case .xctest:
            let frameworkData = try systemFrameworkMetadataProvider.loadMetadata(
                sdkName: "XCTest.framework",
                status: .required,
                platform: target.legacyPlatform,
                source: .developer
            )
            let developerDirectory = try await developerDirectoryProvider.developerDirectory()
            let path = try AbsolutePath(
                validating: developerDirectory.pathString + frameworkData
                    .path.pathString
            )

            let metadata = try await frameworkMetadataProvider.loadMetadata(at: path, status: .required)
            return .framework(
                path: path,
                binaryPath: metadata.binaryPath,
                dsymPath: metadata.dsymPath,
                bcsymbolmapPaths: metadata.bcsymbolmapPaths,
                linking: metadata.linking,
                architectures: metadata.architectures,
                status: .required
            )
        }
    }

    /// Resolves a project-based target dependency into a `GraphDependency`.
    ///
    /// - Parameters:
    ///   - projectPath: The absolute path of the `.xcodeproj` directory.
    ///   - targetName: The name of the target within that project.
    ///   - status: The linking status of the dependency.
    ///   - allTargetsMap: A dictionary of target names to `Target` models for resolution.
    /// - Returns: A `GraphDependency` representing the resolved dependency.
    /// - Throws: `TargetDependencyMappingError.targetNotFound` if `targetName` isn't in `allTargetsMap`,
    ///           `TargetDependencyMappingError.unknownDependencyType` if the product type can't be mapped.
    private func mapProjectGraphDependency(
        projectPath: AbsolutePath,
        targetName: String,
        status: LinkingStatus,
        allTargetsMap: [String: Target]
    ) throws -> GraphDependency {
        guard let target = allTargetsMap[targetName] else {
            throw TargetDependencyMappingError.targetNotFound(
                targetName: targetName,
                path: projectPath
            )
        }

        let product = target.product
        switch product {
        case .framework, .staticFramework:
            let linking: BinaryLinking = (product == .staticFramework) ? .static : .dynamic
            return .framework(
                path: projectPath,
                binaryPath: projectPath.appending(component: "\(targetName).framework"),
                dsymPath: nil,
                bcsymbolmapPaths: [],
                linking: linking,
                architectures: [],
                status: status
            )

        case .staticLibrary, .dynamicLibrary:
            let linking: BinaryLinking = (product == .staticLibrary) ? .static : .dynamic
            let libName = (linking == .static) ? "lib\(targetName).a" : "lib\(targetName).dylib"
            let publicHeadersPath = projectPath.appending(component: "include")
            return .library(
                path: projectPath.appending(component: libName),
                publicHeaders: publicHeadersPath,
                linking: linking,
                architectures: [],
                swiftModuleMap: nil
            )

        case .bundle:
            return .bundle(path: projectPath.appending(component: "\(targetName).bundle"))

        case .app, .commandLineTool:
            return .target(name: targetName, path: projectPath, status: status)

        default:
            throw TargetDependencyMappingError.unknownDependencyType(name: product.description)
        }
    }
}

/// Resolves the system-provided `XCTest.framework` path, falling back to a standard location
/// inside the selected Xcode’s SharedFrameworks directory.
///
/// - Parameter developerDirectoryProvider: Provides the current Xcode Developer directory (via `xcode-select -p`).
/// - Returns: The absolute path to `XCTest.framework`.
/// - Throws: If the developer directory cannot be retrieved or validated.
private func xctestFrameworkPath(
    developerDirectoryProvider: DeveloperDirectoryProviding = DeveloperDirectoryProvider()
) async throws -> AbsolutePath {
    let devDir = try await developerDirectoryProvider.developerDirectory()
    // Typically: /Applications/Xcode.app/Contents/Developer
    // Move one directory up (/Contents) and then into SharedFrameworks/XCTest.framework
    return devDir.parentDirectory.appending(components: ["SharedFrameworks", "XCTest.framework"])
}

extension TargetDependency.PackageType {
    /// Translates `TargetDependency.PackageType` into `GraphDependency.PackageProductType`.
    var graphPackageType: GraphDependency.PackageProductType {
        switch self {
        case .runtime:
            return .runtime
        case .runtimeEmbedded:
            return .runtimeEmbedded
        case .plugin:
            return .plugin
        case .macro:
            return .macro
        }
    }
}

extension PBXProductType {
    /// Maps `PBXProductType` to a `Product`, or returns `nil` if unsupported.
    func mapProductType() -> Product? {
        switch self {
        case .application, .messagesApplication, .onDemandInstallCapableApplication:
            return .app
        case .framework, .xcFramework:
            return .framework
        case .staticFramework:
            return .staticFramework
        case .dynamicLibrary:
            return .dynamicLibrary
        case .staticLibrary, .metalLibrary:
            return .staticLibrary
        case .bundle, .ocUnitTestBundle:
            return .bundle
        case .unitTestBundle:
            return .unitTests
        case .uiTestBundle:
            return .uiTests
        case .appExtension:
            return .appExtension
        case .extensionKitExtension, .xcodeExtension:
            return .extensionKitExtension
        case .commandLineTool:
            return .commandLineTool
        case .messagesExtension:
            return .messagesExtension
        case .stickerPack:
            return .stickerPackExtension
        case .xpcService:
            return .xpc
        case .watchApp, .watch2App, .watch2AppContainer:
            return .watch2App
        case .watchExtension, .watch2Extension:
            return .watch2Extension
        case .tvExtension:
            return .tvTopShelfExtension
        case .systemExtension:
            return .systemExtension
        case .instrumentsPackage, .intentsServiceExtension, .driverExtension, .none:
            return nil
        }
    }
}

// swiftlint:enable function_body_length

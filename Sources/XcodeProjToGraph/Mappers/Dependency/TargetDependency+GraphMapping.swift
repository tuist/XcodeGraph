import Foundation
import Path
import XcodeGraph
import XcodeProj

extension TargetDependency {
    /// Converts a `TargetDependency` into a corresponding `GraphDependency` model,
    /// resolving any additional details (like linking types, binary paths, or architectures)
    /// based on the dependency type.
    ///
    /// This method leverages information like the source directory and an all-targets map to
    /// resolve project-based target dependencies and to construct the correct `GraphDependency`
    /// variant (e.g., frameworks, libraries, SDKs, packages, etc.).
    ///
    /// - Parameters:
    ///   - sourceDirectory: The root directory from which to resolve relative paths.
    ///   - allTargetsMap: A dictionary mapping target names to `Target` models, used to
    ///     resolve project-based dependencies.
    /// - Returns: A `GraphDependency` model representing this dependency.
    /// - Throws: If a project-based dependency cannot be resolved (e.g., target not found).
    public func graphDependency(
        sourceDirectory: AbsolutePath,
        allTargetsMap: [String: Target]
    ) async throws -> GraphDependency {
        switch self {
        case let .target(name, status, _):
            return .target(name: name, path: sourceDirectory, status: status)

        case let .project(targetName, projectPath, status, _):
            return try mapProjectGraphDependency(
                projectPath: projectPath,
                targetName: targetName,
                status: status,
                allTargetsMap: allTargetsMap
            )

        case let .framework(path, status, _):
            let binaryPath = path.appending(component: "\(name)")
            let architectures = (try? await LipoTool.archs(paths: [binaryPath.pathString]).architectures) ?? []
            return .framework(
                path: path,
                binaryPath: binaryPath,
                dsymPath: nil,
                bcsymbolmapPaths: [],
                linking: .dynamic,
                architectures: architectures,
                status: status
            )

        case let .xcframework(path, status, _):
            return .xcframework(
                GraphDependency.XCFramework(
                    path: path,
                    infoPlist: .test(),
                    linking: .dynamic,
                    mergeable: false,
                    status: status,
                    macroPath: nil,
                    swiftModules: [],
                    moduleMaps: []
                )
            )

        case let .library(path, publicHeaders, swiftModuleMap, _):
            let linking: BinaryLinking = {
                switch path.fileExtension {
                case .staticLibrary:
                    return .static
                case .dynamicLibrary, .textBasedDynamicLibrary:
                    return .dynamic
                default:
                    return .dynamic
                }
            }()
            let architectures = (try? await LipoTool.archs(paths: [path.pathString]).architectures) ?? []

            return .library(
                path: path,
                publicHeaders: publicHeaders,
                linking: linking,
                architectures: architectures,
                swiftModuleMap: swiftModuleMap
            )

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

        case .xctest:
            return .xcframework(
                GraphDependency.XCFramework(
                    path: sourceDirectory,
                    infoPlist: XCFrameworkInfoPlist.test(),
                    linking: .dynamic,
                    mergeable: false,
                    status: .required,
                    macroPath: nil,
                    swiftModules: [],
                    moduleMaps: []
                )
            )
        }
    }

    /// Maps a project-based target dependency into a `GraphDependency` by resolving the target
    /// and determining the appropriate dependency type (e.g., framework, library, bundle, app).
    ///
    /// - Parameters:
    ///   - projectPath: The absolute path of the project containing the target.
    ///   - targetName: The name of the target dependency.
    ///   - status: The linking status of the dependency.
    ///   - allTargetsMap: A dictionary mapping target names to `Target` models.
    /// - Returns: A `GraphDependency` model representing the resolved project target dependency.
    /// - Throws: If the target specified by `targetName` is not found in `allTargetsMap`.
    public func mapProjectGraphDependency(
        projectPath: AbsolutePath,
        targetName: String,
        status: LinkingStatus,
        allTargetsMap: [String: Target]
    ) throws -> GraphDependency {
        guard let target = allTargetsMap[targetName] else {
            throw MappingError.targetNotFound(targetName: targetName, path: projectPath)
        }

        let product = target.product
        let dependency: GraphDependency

        switch product {
        case .framework, .staticFramework:
            let linking: BinaryLinking = (product == .staticFramework) ? .static : .dynamic
            dependency = .framework(
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
            let publicHeadersPath = projectPath.appending(component: "include")
            dependency = .library(
                path: projectPath.appending(
                    component: linking == .static
                        ? "lib\(targetName).a"
                        : "lib\(targetName).dylib"
                ),
                publicHeaders: publicHeadersPath,
                linking: linking,
                architectures: [],
                swiftModuleMap: nil
            )

        case .bundle:
            dependency = .bundle(
                path: projectPath.appending(component: "\(targetName).bundle")
            )

        case .app, .commandLineTool:
            dependency = .target(
                name: targetName,
                path: projectPath,
                status: status
            )

        default:

            throw MappingError.unknownDependencyType(name: product.description)
        }

        return dependency
    }
}

extension TargetDependency.PackageType {
    /// Converts a `TargetDependency.PackageType` into a `GraphDependency.PackageProductType`.
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
    /// Maps a `PBXProductType` into a `Product` domain model.
    ///
    /// - Parameter pbxProductType: The `PBXProductType` to map.
    /// - Returns: A `Product` model if known, or `nil` if the product type is unsupported.
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

        // Unsupported or unknown cases
        case .instrumentsPackage, .intentsServiceExtension, .driverExtension, .none:
            return nil
        }
    }
}

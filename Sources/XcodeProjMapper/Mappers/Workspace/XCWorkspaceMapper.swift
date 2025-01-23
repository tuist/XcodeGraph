import Foundation
import Path
import PathKit
import XcodeGraph
import XcodeProj

/// A protocol defining how to map an `.xcworkspace` into a `Workspace` model.
///
/// Conforming types extract project references, shared schemes, and other relevant data
/// from a workspace to produce a high-level `Workspace` domain model.
protocol WorkspaceMapping {
    /// Maps the `.xcworkspace` into a `Workspace` domain model.
    ///
    /// This includes:
    /// - Identifying all `.xcodeproj` references in the workspace.
    /// - Mapping any shared schemes present in the workspace.
    ///
    /// - Returns: A fully constructed `Workspace` representing the workspace’s structure.
    /// - Throws: If reading projects or schemes fails.
    func map(xcworkspace: XCWorkspace) async throws -> Workspace
}

/// A mapper that converts an `.xcworkspace` into a `Workspace` model.
///
/// `WorkspaceMapper`:
/// - Finds all referenced Xcode projects,
/// - Maps shared schemes, and
/// - Produces a `Workspace` model suitable for analysis or code generation.
struct XCWorkspaceMapper: WorkspaceMapping {
    private let schemeMapper: SchemeMapping

    init(schemeMapper: SchemeMapping = XCSchemeMapper()) {
        self.schemeMapper = schemeMapper
    }

    func map(xcworkspace: XCWorkspace) async throws -> Workspace {
        let xcWorkspacePath = xcworkspace.workspacePath
        let srcPath = xcWorkspacePath.parentDirectory
        let projectPaths = try await extractProjectPaths(
            from: xcworkspace.data.children,
            srcPath: srcPath,
            xcworkspace: xcworkspace
        )
        let workspaceName = xcWorkspacePath.basenameWithoutExt
        let schemes = try mapSchemes(from: xcworkspace)

        let generationOptions = Workspace.GenerationOptions(
            enableAutomaticXcodeSchemes: nil,
            autogeneratedWorkspaceSchemes: .disabled,
            lastXcodeUpgradeCheck: nil,
            renderMarkdownReadme: false
        )

        return Workspace(
            path: srcPath,
            xcWorkspacePath: xcWorkspacePath,
            name: workspaceName,
            projects: projectPaths,
            schemes: schemes,
            generationOptions: generationOptions,
            ideTemplateMacros: nil,
            additionalFiles: []
        )
    }

    // MARK: - Private Helpers

    /// Recursively identifies all `.xcodeproj` files within the workspace structure.
    ///
    /// - Parameters:
    ///   - elements: The workspace elements (files/groups).
    ///   - srcPath: The source directory path used for resolving relative references.
    /// - Returns: An array of absolute paths to `.xcodeproj` directories.
    private func extractProjectPaths(
        from elements: [XCWorkspaceDataElement],
        srcPath: AbsolutePath,
        xcworkspace: XCWorkspace
    ) async throws -> [AbsolutePath] {
        var paths = [AbsolutePath]()

        for element in elements {
            switch element {
            case let .file(ref):
                let refPath = try await ref.path(srcPath: srcPath)
                if refPath.fileExtension == .xcodeproj {
                    paths.append(refPath)
                }
            case let .group(group):
                let nestedSrcPath = srcPath.appending(component: group.location.path)
                let groupPaths = try await extractProjectPaths(
                    from: group.children,
                    srcPath: nestedSrcPath,
                    xcworkspace: xcworkspace
                )
                paths.append(contentsOf: groupPaths)
            }
        }

        return paths
    }

    /// Maps shared schemes defined within the workspace.
    ///
    /// Schemes are typically located in `xcshareddata/xcschemes`. If found,
    /// this method parses them and maps them into `Scheme` models.
    ///
    /// - Parameter srcPath: The workspace's root path.
    /// - Returns: An array of `Scheme` instances for shared schemes in the workspace.
    private func mapSchemes(
        from xcworkspace: XCWorkspace
    ) throws -> [Scheme] {
        let srcPath = xcworkspace.workspacePath.parentDirectory
        let sharedDataPath = Path(srcPath.pathString) + "xcshareddata/xcschemes"
        guard sharedDataPath.exists else { return [] }
        let schemePaths = try sharedDataPath.children().filter { $0.extension == "xcscheme" }

        return try schemePaths.map { schemePath in
            try schemeMapper.map(
                try XCScheme(path: schemePath),
                shared: true,
                graphType: .workspace(xcworkspace)
            )
        }
    }
}

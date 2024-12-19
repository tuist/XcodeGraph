import Foundation
import InlineSnapshotTesting
import Path
import Testing
import XcodeProj
import XcodeProjMapper
@testable import XcodeGraph

// The IntegrationTests suite is serialized and uses inline snapshot testing.
// If a test fails, its snapshot can be re-recorded as needed by changing `record: .failed`.
@Suite(
    // TODO: - Remove this when no longer lazy unzipping fixtures
    .serialized,
    .snapshots(
        record: .failed
    )
)
struct IntegrationTests {
    /// Asserts that the given graph parsed from a workspace fixture matches the provided inline snapshots.
    ///
    /// - Parameters:
    ///   - fixture: A closure that returns a `WorkspaceFixture` used to generate the graph.
    func assertGraph(
        of fixture: () -> WorkspaceFixture,
        name: (() -> String)? = nil,
        dependencies: (() -> String)? = nil,
        dependencyConditions: (() -> String)? = nil,
        packages: (() -> String)? = nil,
        workspace: (() -> String)? = nil,
        projects: (() -> String)? = nil,
        fileID: StaticString = #fileID,
        file filePath: StaticString = #filePath,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt = #column
    ) throws {
        let path = try fixture().absolutePath()

        let parser = ProjectParser()
        let fullGraph: XcodeGraph.Graph = try parser.parse(at: path.pathString)
        let graph = try fullGraph.normalizeGraphPaths().minimizeGraph()

        // A helper for making assertions more concise.
        func assertSnapshot(
            of value: some Any,
            label: String,
            trailingClosureOffset: Int,
            matches expected: (() -> String)?,
            message: String
        ) {
            assertInlineSnapshot(
                of: value,
                as: .dump,
                message: message,
                syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
                    trailingClosureLabel: label,
                    trailingClosureOffset: trailingClosureOffset
                ),
                matches: expected,
                fileID: fileID,
                file: filePath,
                function: function,
                line: line,
                column: column
            )
        }

        // Assertions for each portion of the graph.
        assertSnapshot(
            of: graph.name,
            label: "name",
            trailingClosureOffset: 1,
            matches: name,
            message: "Graph name did not match"
        )

        assertSnapshot(
            of: graph.dependencies,
            label: "dependencies",
            trailingClosureOffset: 2,
            matches: dependencies,
            message: "Dependencies did not match"
        )

        assertSnapshot(
            of: graph.dependencyConditions,
            label: "dependencyConditions",
            trailingClosureOffset: 3,
            matches: dependencyConditions,
            message: "Dependency Conditions did not match"
        )

        assertSnapshot(
            of: graph.packages,
            label: "packages",
            trailingClosureOffset: 4,
            matches: packages,
            message: "Packages did not match"
        )

        assertSnapshot(
            of: graph.workspace,
            label: "workspace",
            trailingClosureOffset: 5,
            matches: workspace,
            message: "Workspace did not match"
        )

        assertSnapshot(
            of: graph.projects,
            label: "projects",
            trailingClosureOffset: 6,
            matches: projects,
            message: "Projects did not match"
        )
    }
}

// MARK: - Graph Normalization & Minimization

extension XcodeGraph.Graph {
    /// Normalizes file paths in the graph's JSON representation to a consistent relative form.
    func normalizeGraphPaths() throws -> XcodeGraph.Graph {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(self)
        var jsonString = String(decoding: data, as: UTF8.self)

        // Replace any path prefix before /Fixtures with a unified placeholder.
        jsonString = jsonString.replacingOccurrences(
            of: #"[^"]*?/Fixtures"#,
            with: "/Fixtures",
            options: [.regularExpression]
        )

        let decoder = JSONDecoder()
        return try decoder.decode(XcodeGraph.Graph.self, from: Data(jsonString.utf8))
    }

    /// Minimizes the graph's data by removing unnecessary details (e.g., schemes, resource synthesizers).
    func minimizeGraph() -> Graph {
        var graph = self

        // Remove workspace schemes and standardize generation options.
        graph.workspace.schemes = []
        graph.workspace.generationOptions = .test()

        for (key, project) in graph.projects {
            graph.projects[key]?.schemes = []
            graph.projects[key]?.resourceSynthesizers = []
            graph.projects[key]?.settings = Settings(configurations: [:])

            for targetKey in project.targets.keys {
                // Remove unneeded properties from targets.
                graph.projects[key]?.targets[targetKey]?.scripts = []
                graph.projects[key]?.targets[targetKey]?.playgrounds = []
                graph.projects[key]?.targets[targetKey]?.rawScriptBuildPhases = []
                graph.projects[key]?.targets[targetKey]?.buildRules = []
                graph.projects[key]?.targets[targetKey]?.settings = nil
                graph.projects[key]?.targets[targetKey]?.infoPlist = nil
                graph.projects[key]?.targets[targetKey]?.destinations = []
            }
        }

        return graph
    }
}

// Allows AbsolutePath to be displayed in snapshots in a readable form.
extension AbsolutePath: @retroactive AnySnapshotStringConvertible {
    public var snapshotDescription: String { pathString }
}

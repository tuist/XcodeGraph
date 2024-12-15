import Foundation
import InlineSnapshotTesting
import Path
import Testing
import XcodeGraph
import XcodeProjToGraph
import XcodeProj
import RegexBuilder

@testable import TestSupport

struct GraphDependencyTestableMap: Encodable, Comparable {
    static func < (lhs: GraphDependencyTestableMap, rhs: GraphDependencyTestableMap) -> Bool {
        lhs.key < rhs.key
    }

    let key: GraphDependency
    let values: [GraphDependency]

    init(key: GraphDependency, values: Set<GraphDependency>) {
        self.key = key
        self.values = Array(values).sorted()
    }
}

@Suite(
    .snapshots(
        // Change this re-recored etc
        record: .failed
    )
)
struct IntegrationTests {
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
    ) async throws {

        let path = try fixture().absolutePath()

        let fullGraph: XcodeGraph.Graph = try await ProjectParser.parse(atPath: path.pathString)

        let graph = try fullGraph.normalizeGraphPaths().minimizeGraph()

        assertInlineSnapshot(
            of: graph.name,
            as: .dump,
            message: "Dependency Conditions did not match",
            syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
                trailingClosureLabel: "name",
                trailingClosureOffset: 1
            ),
            matches: name,
            fileID: fileID,
            file: filePath,
            function: function,
            line: line,
            column: column
        )
        assertInlineSnapshot(
            of: graph.dependencies,
            as: .dump,
            message: "Dependencies did not match",
            syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
                trailingClosureLabel: "dependencies",
                trailingClosureOffset: 2
            ),
            matches: dependencies,
            fileID: fileID,
            file: filePath,
            function: function,
            line: line,
            column: column
        )
        assertInlineSnapshot(
            of: graph.dependencyConditions,
            as: .dump,
            message: "Dependency Conditions did not match",
            syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
                trailingClosureLabel: "dependencyConditions",
                trailingClosureOffset: 3
            ),
            matches: dependencyConditions,
            fileID: fileID,
            file: filePath,
            function: function,
            line: line,
            column: column
        )
        assertInlineSnapshot(
            of: graph.packages,
            as: .dump,
            message: "Packages did not match",
            syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
                trailingClosureLabel: "packages",
                trailingClosureOffset: 4
            ),
            matches: packages,
            fileID: fileID,
            file: filePath,
            function: function,
            line: line,
            column: column
        )
        assertInlineSnapshot(
            of: graph.workspace,
            as: .dump,
            message: "Workspace did not match",
            syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
                trailingClosureLabel: "workspace",
                trailingClosureOffset: 5
            ),
            matches: workspace,
            fileID: fileID,
            file: filePath,
            function: function,
            line: line,
            column: column
        )
        assertInlineSnapshot(
            of: graph.projects,
            as: .dump,
            message: "Projects did not match",
            syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
                trailingClosureLabel: "projects",
                trailingClosureOffset: 6
            ),
            matches: projects,
            fileID: fileID,
            file: filePath,
            function: function,
            line: line,
            column: column
        )
    }
}

extension XcodeGraph.Graph {
    func normalizeGraphPaths() throws -> XcodeGraph.Graph {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let data = try encoder.encode(self)
        var jsonString = String(decoding: data, as: UTF8.self)

        // Normalize any prefix before /Fixtures.
        jsonString = jsonString.replacingOccurrences(
            of: #"[^"]*?/Fixtures"#,
            with: "/Fixtures",
            options: [.regularExpression]
        )

        let decoder = JSONDecoder()
        let normalizedGraph = try decoder.decode(XcodeGraph.Graph.self, from: Data(jsonString.utf8))

        return normalizedGraph
    }

    func minimizeGraph() -> Graph {
            var graph = self
            graph.workspace.schemes = []
            graph.workspace.generationOptions = .test()

            for (key, project) in graph.projects {
                graph.projects[key]?.schemes = []
                graph.projects[key]?.resourceSynthesizers = []
                graph.projects[key]?.settings = Settings(configurations: [:])

                for targetKey in project.targets.keys {
                    graph.projects[key]?.targets[targetKey]?.scripts = []
                    graph.projects[key]?.targets[targetKey]?.playgrounds = []
                    graph.projects[key]?.targets[targetKey]?.rawScriptBuildPhases = []
                    graph.projects[key]?.targets[targetKey]?.playgrounds = []
                    graph.projects[key]?.targets[targetKey]?.buildRules = []
                    graph.projects[key]?.targets[targetKey]?.settings = nil
                    graph.projects[key]?.targets[targetKey]?.infoPlist = nil
                    graph.projects[key]?.targets[targetKey]?.destinations = []
                }
            }

            return graph
    }
}

extension AbsolutePath: @retroactive AnySnapshotStringConvertible {
  public var snapshotDescription: String {
      return self.pathString
  }
}

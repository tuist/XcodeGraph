import Path
import Testing
import XcodeGraph
import XcodeProj
@testable import XcodeProjMapper

extension PBXProjectMapper {
    /// Creates and maps a test project with given targets.
    func createMappedProject(
        projectName: String = "TestProject",
        targets: [PBXNativeTarget] = []
    ) throws -> Project {
        let provider = MockProjectProvider.makeBasicProjectProvider(projectName: projectName)
        try provider.addTargets(targets)

        let mapper = PBXProjectMapper()
        return try mapper.map(projectProvider: provider)
    }

    /// Creates a mapped graph from multiple project providers, useful for testing multi-project scenarios.
    func createMappedGraph(
        graphType: GraphType,
        projectProviders: [AbsolutePath: MockProjectProvider]
    ) throws -> XcodeGraph.Graph {
        let mapper = GraphMapper(graphType: graphType) { path in
            guard let provider = projectProviders[path] else {
                Issue.record("Unexpected project path requested: \(path)")
                throw XcodeProjMapper.XcodeProjError.noProjectsFound
            }
            return provider
        }

        return try mapper.map()
    }
}

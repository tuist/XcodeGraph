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
    ) async throws -> Project {
        let provider = MockProjectProvider.makeBasicProjectProvider(projectName: projectName)
        try provider.addTargets(targets)

        let mapper = PBXProjectMapper()
        return try await mapper.map(xcodeProj: provider.xcodeProj)
    }
}

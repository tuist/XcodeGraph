import Foundation
import InlineSnapshotTesting
import Path
import Testing
import XcodeGraph
import XcodeProj
import XcodeProjToGraph

@testable import TestSupport

extension IntegrationTests {
    @Test("Maps a large iOS app project into the correct graph")
    func iosAppLarge() async throws {
        let path = try WorkspaceFixture.iosAppLarge.absolutePath()

        let graph: XcodeGraph.Graph = try await ProjectParser.parse(projectType: .workspace(path))

        #expect(graph.projects.first?.value.targets.count == 300)
    }
}

import Foundation
import InlineSnapshotTesting
import Path
import Testing
import XcodeGraph
import XcodeProj
import XcodeProjMapper

extension IntegrationTests {
    @Test("Maps a large iOS app project into the correct graph")
    func iosAppLarge() throws {
        let path = try WorkspaceFixture.iosAppLarge.absolutePath()

        let parser = ProjectParser()
        let graph: XcodeGraph.Graph = try parser.parse(at: path.pathString)
        #expect(graph.projects.first?.value.targets.count == 300)
    }
}

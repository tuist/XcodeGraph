import Foundation
import InlineSnapshotTesting
import Path
import Testing
import XcodeGraph
import XcodeProjToGraph
import XcodeProj

@testable import TestSupport

extension IntegrationTests {
  @Test
  func iosAppLarge() async throws {
    let path = try WorkspaceFixture.iosAppLarge.absolutePath()

    let graph: XcodeGraph.Graph = try await ProjectParser.parse(projectType: .workspace(path))

      #expect(graph.projects.first?.value.targets.count == 300)
  }
}

import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import XcodeProjToGraph

struct MockWorkspaceProvider: WorkspaceProviding {
    var workspaceDirectory: AbsolutePath
    var xcWorkspacePath: AbsolutePath
      var xcworkspace: XCWorkspace

  public init(xcWorkspacePath: AbsolutePath, xcworkspace: XCWorkspace) {
    self.xcWorkspacePath = xcWorkspacePath
      self.workspaceDirectory = xcWorkspacePath.parentDirectory
    self.xcworkspace = xcworkspace
  }
}

struct MockProjectProvider: ProjectProviding {
  let sourceDirectory: AbsolutePath
  let xcodeProjPath: AbsolutePath
  let xcodeProj: XcodeProj
  var pbxProj: PBXProj {
    xcodeProj.pbxproj
  }

  init(
    sourceDirectory: String = "/tmp",
    projectName: String = "TestProject",
    configurationList: XCConfigurationList? = nil,
    pbxProj: PBXProj = PBXProj()
  ) {
    let configurationList = configurationList ?? .mock(proj: pbxProj)
    self.sourceDirectory = try! AbsolutePath.resolvePath(sourceDirectory)
    self.xcodeProjPath = self.sourceDirectory.appending(component: "TestProject.xcodproj")
    // minimal project setup
    let pbxProject = PBXProject.mock(
      name: projectName, buildConfigurationList: configurationList, pbxProj: pbxProj)
    pbxProj.add(object: pbxProject)
    pbxProj.add(object: configurationList)
    pbxProj.rootObject = pbxProject

    self.xcodeProj = XcodeProj(workspace: XCWorkspace(), pbxproj: pbxProj)
  }

  func pbxProject() throws -> PBXProject {
    return xcodeProj.pbxproj.projects.first!
  }
}

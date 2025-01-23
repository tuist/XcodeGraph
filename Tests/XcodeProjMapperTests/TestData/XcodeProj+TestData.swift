import XcodeProj

extension XcodeProj {
    static func test(
        projectName: String = "MainApp",
        configurationList: XCConfigurationList = XCConfigurationList.test(
            buildConfigurations: [.testDebug(), .testRelease()]
        ),
        mainGroup: PBXGroup,
        targets: [PBXTarget] = [PBXNativeTarget.test()]
    ) -> XcodeProj {
        let pbxProj = PBXProj()
        let pbxProject = PBXProject.test(
            name: projectName,
            buildConfigurationList: configurationList,
            mainGroup: mainGroup,
            targets: targets
        )
        pbxProj.rootObject = pbxProject

        let workspace = XCWorkspace.test(files: ["App/\(projectName).xcodeproj"], path: "App/\(projectName).xcworkspace")
        return XcodeProj(workspace: workspace, pbxproj: pbxProj)
    }
}

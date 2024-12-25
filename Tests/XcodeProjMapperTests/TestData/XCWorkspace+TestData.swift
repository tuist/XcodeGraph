import XcodeProj

extension XCWorkspace {
    static func test(
        files: [String] = [
            "App/MainApp.xcodeproj",
            "Framework1/Framework1.xcodeproj",
            "StaticFramework1/StaticFramework1.xcodeproj",
        ]
    ) -> XCWorkspace {
        let children = files.map { path in
            XCWorkspaceDataElement.file(XCWorkspaceDataFileRef(location: .group(path)))
        }
        return XCWorkspace(data: XCWorkspaceData(children: children))
    }

    static func test(withElements elements: [XCWorkspaceDataElement]) -> XCWorkspace {
        let data = XCWorkspaceData(children: elements)
        return XCWorkspace(data: data)
    }
}

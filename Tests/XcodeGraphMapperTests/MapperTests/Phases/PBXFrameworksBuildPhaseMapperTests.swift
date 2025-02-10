import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import XcodeGraphMapper

@Suite
struct PBXFrameworksBuildPhaseMapperTests {
    @Test("Maps frameworks from frameworks phase")
    func testMapFrameworks() async throws {
        // Given
        let xcodeProj = try await XcodeProj.test()
        let pbxProj = xcodeProj.pbxproj

        let frameworkRef = try PBXFileReference(
            sourceTree: .group,
            name: "MyFramework.framework",
            path: "Frameworks/MyFramework.framework"
        )
        .add(to: pbxProj)
        .addToMainGroup(in: pbxProj)
        let frameworkBuildFile = PBXBuildFile(file: frameworkRef).add(to: pbxProj)

        let targetFrameworkRef = PBXFileReference(
            sourceTree: .buildProductsDir,
            path: "Target.framework"
        )
        let targetFrameworkBuildFile = PBXBuildFile(file: targetFrameworkRef).add(to: pbxProj)

        let projectTargetPath = xcodeProj.projectPath.parentDirectory.appending(
            components: "AnotherProject",
            "AnotherProject.xcodeproj"
        )
        let projectTargetFrameworkRef = PBXFileReference(
            sourceTree: .buildProductsDir,
            path: "ProjectTarget.framework"
        )
        let projectTargetFrameworkBuildFile = PBXBuildFile(file: projectTargetFrameworkRef).add(to: pbxProj)

        let weakProjectTargetFrameworkRef = PBXFileReference(
            sourceTree: .buildProductsDir,
            path: "WeakProjectTarget.framework"
        )
        let weakProjectTargetFrameworkBuildFile = PBXBuildFile(
            file: weakProjectTargetFrameworkRef,
            settings: ["ATTRIBUTES": ["Weak"]]
        ).add(to: pbxProj)

        let frameworksPhase = PBXFrameworksBuildPhase(
            files: [
                frameworkBuildFile,
                targetFrameworkBuildFile,
                projectTargetFrameworkBuildFile,
                weakProjectTargetFrameworkBuildFile,
            ]
        ).add(to: pbxProj)

        try PBXNativeTarget(
            name: "App",
            buildPhases: [frameworksPhase],
            productType: .application
        )
        .add(to: pbxProj)
        .add(to: pbxProj.rootObject)

        PBXNativeTarget(
            name: "Target",
            buildPhases: [frameworksPhase],
            productType: .framework
        )
        .add(to: pbxProj)

        let mapper = PBXFrameworksBuildPhaseMapper()

        // When
        let frameworks = try await mapper.map(
            frameworksPhase,
            xcodeProj: xcodeProj,
            projectNativeTargets: [
                "ProjectTarget": ProjectNativeTarget(
                    nativeTarget: .test(
                        name: "ProjectTarget"
                    ),
                    project: .test(
                        path: projectTargetPath
                    )
                ),
                "WeakProjectTarget": ProjectNativeTarget(
                    nativeTarget: .test(
                        name: "WeakProjectTarget"
                    ),
                    project: .test(
                        path: projectTargetPath
                    )
                ),
            ]
        )

        // Then
        let frameworkPath = try AbsolutePath(validating: "/tmp/TestProject/Frameworks/MyFramework.framework")
        #expect(
            frameworks.sorted(by: { $0.name < $1.name }) == [
                .framework(
                    path: frameworkPath,
                    status: .required,
                    condition: nil
                ),
                .project(
                    target: "ProjectTarget",
                    path: projectTargetPath.parentDirectory,
                    status: .required,
                    condition: nil
                ),
                .target(
                    name: "Target",
                    status: .required,
                    condition: nil
                ),
                .project(
                    target: "WeakProjectTarget",
                    path: projectTargetPath.parentDirectory,
                    status: .optional,
                    condition: nil
                ),
            ]
        )
    }
}

import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

struct DependencyMapperTests {
    let mockProvider = MockProjectProvider()
    let mapper: DependencyMapping

    init() {
        mapper = DependencyMapper(projectProvider: mockProvider)
    }

    @Test func testDirectTargetMapping() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        let dep = PBXTargetDependency.mockTargetDependency(
            name: "DirectTarget",
            pbxProj: pbxProj
        )
        let target = PBXNativeTarget.mock(
            name: "App",
            dependencies: [dep],
            productType: .application,
            pbxProj: pbxProj
        )

        let mapped = try await mapper.mapDependencies(target: target)
        #expect(mapped.count == 1)
        #expect(mapped.first == .target(name: "DirectTarget", status: .required, condition: nil))
    }

    @Test func testPackageProductMapping() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        let dep = PBXTargetDependency.mockPackageProductDependency(
            productName: "MyPackageProduct",
            pbxProj: pbxProj
        )
        let target = PBXNativeTarget.mock(
            name: "App",
            dependencies: [dep],
            productType: .application,
            pbxProj: pbxProj
        )

        let mapped = try await mapper.mapDependencies(target: target)
        #expect(mapped.count == 1)
        #expect(mapped.first == .package(product: "MyPackageProduct", type: .runtime, condition: nil))
    }

    @Test func testProxyNativeTarget() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        // Native target proxy referencing a target in the same project
        let project = pbxProj.projects.first!
        let dep = PBXTargetDependency.mockProxyDependency(
            remoteInfo: "NativeTarget",
            proxyType: .nativeTarget,
            containerPortal: .project(project),
            pbxProj: pbxProj
        )
        let target = PBXNativeTarget.mock(
            name: "App",
            dependencies: [dep],
            productType: .application,
            pbxProj: pbxProj
        )

        let mapped = try await mapper.mapDependencies(target: target)
        #expect(mapped.count == 1)
        #expect(mapped.first == .target(name: "NativeTarget", status: .required, condition: nil))
    }

    @Test func testProxyProjectReference() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        let fileRef = PBXFileReference.mock(
            path: "OtherProject.xcodeproj",
            pbxProj: pbxProj
        )

        let dep = PBXTargetDependency.mockProxyDependency(
            remoteInfo: "OtherTarget",
            proxyType: .nativeTarget,
            containerPortal: .fileReference(fileRef),
            pbxProj: pbxProj
        )
        let target = PBXNativeTarget.mock(
            name: "App",
            dependencies: [dep],
            productType: .application,
            pbxProj: pbxProj
        )

        let mapped = try await mapper.mapDependencies(target: target)
        #expect(mapped.count == 1)
        let result = mapped.first!
        let expectedPath = try AbsolutePath.resolvePath(
            mockProvider.sourceDirectory.pathString + "OtherProject.xcodeproj"
        )
        #expect(
            result
                == .project(target: "OtherTarget", path: expectedPath, status: .required, condition: nil)
        )
    }

    @Test func testProxyReferenceProxyLibrary() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        let referenceProxy = PBXReferenceProxy(
            fileType: "compiled.mach-o.dylib",
            path: "libTest.dylib",
            remote: nil,
            sourceTree: .group
        )
        pbxProj.add(object: referenceProxy)

        let projectRef = PBXProject.mock(name: "RemoteProject", pbxProj: pbxProj)
        let dep = PBXTargetDependency.mockProxyDependency(
            remoteInfo: "SomeRemoteInfo",
            proxyType: .reference,
            containerPortal: .project(projectRef),
            pbxProj: pbxProj,
            remoteObject: referenceProxy
        )
        let target = PBXNativeTarget.mock(
            name: "App",
            dependencies: [dep],
            productType: .application,
            pbxProj: pbxProj
        )

        let mapped = try await mapper.mapDependencies(target: target)
        #expect(mapped.count == 1)
        let result: TargetDependency = mapped.first!
        let expectedPath = mockProvider.sourceDirectory.appending(component: "libTest.dylib")
        let publicHeaders = try AbsolutePath(validating: "/tmp")
        #expect(
            result
                == TargetDependency.library(
                    path: expectedPath, publicHeaders: publicHeaders, swiftModuleMap: nil, condition: nil
                )
        )
    }

    @Test func testProxyReferenceFileFramework() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        let fileRef = PBXFileReference.mock(
            path: "MyLib.framework",
            pbxProj: pbxProj
        )

        let projectRef = PBXProject.mock(name: "RemoteProject", pbxProj: pbxProj)
        let dep = PBXTargetDependency.mockProxyDependency(
            remoteInfo: "SomeFramework",
            proxyType: .reference,
            containerPortal: .project(projectRef),
            pbxProj: pbxProj,
            remoteObject: fileRef
        )
        let target = PBXNativeTarget.mock(
            name: "App",
            dependencies: [dep],
            productType: .application,
            pbxProj: pbxProj
        )

        let mapped = try await mapper.mapDependencies(target: target)
        #expect(mapped.count == 1)
        let result = mapped.first!
        let expectedPath = mockProvider.sourceDirectory.appending(component: "MyLib.framework")
        #expect(
            result == TargetDependency.framework(path: expectedPath, status: .required, condition: nil)
        )
    }

    @Test func testPlatformConditions() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        let dep = PBXTargetDependency.mockTargetDependency(
            name: "ConditionalTarget",
            platformFilters: ["macos", "ios"],
            pbxProj: pbxProj
        )
        let target = PBXNativeTarget.mock(
            name: "App",
            dependencies: [dep],
            productType: .application,
            pbxProj: pbxProj
        )

        let mapped = try await mapper.mapDependencies(target: target)
        #expect(mapped.count == 1)
        let result = mapped.first!
        let condition = PlatformCondition.when([.ios, .macos])
        #expect(result == .target(name: "ConditionalTarget", status: .required, condition: condition))
    }

    @Test func testNoMatches() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        // A dependency with no target, no product, no proxy - unhandled
        let dep = PBXTargetDependency.mock(name: nil, pbxProj: pbxProj)
        let target = PBXNativeTarget.mock(
            name: "App",
            dependencies: [dep],
            productType: .application,
            pbxProj: pbxProj
        )

        let mapped = try await mapper.mapDependencies(target: target)
        #expect(mapped.count == 0)
    }

    @Test func testFileDependencyMapper() async throws {
        // Test a known path extension scenario
        let fdm = FileDependencyMapper(projectProvider: mockProvider)
        let dependency = try await fdm.mapDependency(pathString: "libStatic.a", condition: nil)
        let expectedPath = mockProvider.sourceDirectory.appending(component: "libStatic.a")
        let publicHeaders = try AbsolutePath(validating: "/tmp")
        #expect(
            dependency
                == TargetDependency.library(
                    path: expectedPath, publicHeaders: publicHeaders, swiftModuleMap: nil, condition: nil
                )
        )
    }

    @Test func testSinglePlatformFilter() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        let dep = PBXTargetDependency.mockTargetDependency(
            name: "SinglePlatform",
            platformFilter: "tvos",
            pbxProj: pbxProj
        )
        let target = PBXNativeTarget.mock(
            name: "App",
            dependencies: [dep],
            productType: .application,
            pbxProj: pbxProj
        )

        let mapped = try await mapper.mapDependencies(target: target)
        #expect(mapped.count == 1)
        #expect(
            mapped.first == .target(name: "SinglePlatform", status: .required, condition: .when([.tvos]))
        )
    }

    @Test func testInvalidPlatformFilter() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        let dep = PBXTargetDependency.mockTargetDependency(
            name: "UnknownPlatform",
            platformFilter: "weirdos",
            pbxProj: pbxProj
        )
        let target = PBXNativeTarget.mock(
            name: "App",
            dependencies: [dep],
            productType: .application,
            pbxProj: pbxProj
        )

        let mapped = try await mapper.mapDependencies(target: target)
        #expect(mapped.count == 1)
        // Unknown platform => condition == nil
        #expect(mapped.first == .target(name: "UnknownPlatform", status: .required, condition: nil))
    }
}

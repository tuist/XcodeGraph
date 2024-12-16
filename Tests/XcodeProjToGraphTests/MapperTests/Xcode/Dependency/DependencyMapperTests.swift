import Path
import Testing
import XcodeGraph
import XcodeProj

@testable import TestSupport
@testable import XcodeProjToGraph

@Suite
struct DependencyMapperTests {
    let mockProvider = MockProjectProvider()
    let mapper: DependencyMapping

    init() {
        mapper = DependencyMapper(projectProvider: mockProvider)
    }

    @Test("Maps direct target dependencies correctly")
    func testDirectTargetMapping() async throws {
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

    @Test("Maps package product dependencies to runtime package targets")
    func testPackageProductMapping() async throws {
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

    @Test("Maps native target proxies referencing targets in the same project")
    func testProxyNativeTarget() async throws {
        let pbxProj = mockProvider.xcodeProj.pbxproj
        let project = try #require(pbxProj.projects.first)
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

    @Test("Maps proxy dependencies to projects referenced by file references")
    func testProxyProjectReference() async throws {
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
        let result = try #require(mapped.first)
        let expectedPath = try AbsolutePath.resolvePath(
            mockProvider.sourceDirectory.pathString + "OtherProject.xcodeproj"
        )
        #expect(result == .project(target: "OtherTarget", path: expectedPath, status: .required, condition: nil))
    }

    @Test("Maps reference proxies to libraries when file type is a dylib")
    func testProxyReferenceProxyLibrary() async throws {
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
        let result = try #require(mapped.first)
        let expectedPath = mockProvider.sourceDirectory.appending(component: "libTest.dylib")
        let publicHeaders = try AbsolutePath(validating: "/tmp")
        #expect(
            result == .library(
                path: expectedPath, publicHeaders: publicHeaders, swiftModuleMap: nil, condition: nil
            )
        )
    }

    @Test("Maps framework references correctly when encountered as proxy references")
    func testProxyReferenceFileFramework() async throws {
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
        let result = try #require(mapped.first)
        let expectedPath = mockProvider.sourceDirectory.appending(component: "MyLib.framework")
        #expect(result == .framework(path: expectedPath, status: .required, condition: nil))
    }

    @Test("Maps dependencies with platform filters to conditions")
    func testPlatformConditions() async throws {
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
        let result = try #require(mapped.first)
        let condition = PlatformCondition.when([.ios, .macos])
        #expect(result == .target(name: "ConditionalTarget", status: .required, condition: condition))
    }

    @Test("Ignores dependencies that cannot be matched to targets, products, or proxies")
    func testNoMatches() async throws {
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
        #expect(mapped.isEmpty == true)
    }

    @Test("Maps known file dependencies (like static libraries) correctly")
    func testFileDependencyMapper() async throws {
        let fdm = FileDependencyMapper(projectProvider: mockProvider)
        let dependency = try await fdm.mapDependency(pathString: "libStatic.a", condition: nil)
        let expectedPath = mockProvider.sourceDirectory.appending(component: "libStatic.a")
        let publicHeaders = try AbsolutePath(validating: "/tmp")
        #expect(
            dependency == .library(
                path: expectedPath, publicHeaders: publicHeaders, swiftModuleMap: nil, condition: nil
            )
        )
    }

    @Test("Maps single-platform filter dependencies correctly")
    func testSinglePlatformFilter() async throws {
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

    @Test("Ignores invalid platform filters and maps dependency without conditions")
    func testInvalidPlatformFilter() async throws {
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

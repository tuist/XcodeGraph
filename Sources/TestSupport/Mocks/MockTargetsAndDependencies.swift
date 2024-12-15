import Foundation
import Path
import XcodeGraph
@testable @preconcurrency import XcodeProj

extension PBXTargetDependency {
    public static func mock(
        name: String? = "App",
        target: PBXTarget? = nil,
        targetProxy: PBXContainerItemProxy? = nil,
        platformFilter: String? = nil,
        platformFilters: [String]? = nil,
        pbxProj: PBXProj
    ) -> PBXTargetDependency {
        let dependency = PBXTargetDependency(
            name: name,
            platformFilter: platformFilter,
            platformFilters: platformFilters,
            target: target,
            targetProxy: targetProxy
        )
        pbxProj.add(object: dependency)
        return dependency
    }
}

extension PBXContainerItemProxy {
    public static func mock(
        containerPortal: PBXContainerItemProxy.ContainerPortal,
        proxyType: PBXContainerItemProxy.ProxyType = .nativeTarget,
        remoteGlobalID: PBXContainerItemProxy.RemoteGlobalID = .string("TARGET_REF"),
        remoteInfo: String? = "App",
        pbxProj: PBXProj
    ) -> PBXContainerItemProxy {
        let proxy = PBXContainerItemProxy(
            containerPortal: containerPortal,
            remoteGlobalID: remoteGlobalID,
            proxyType: proxyType,
            remoteInfo: remoteInfo
        )
        pbxProj.add(object: proxy)
        return proxy
    }
}

extension PBXTargetDependency {
    public static func mockTargetDependency(
        name: String,
        platformFilters: [String]? = nil,
        platformFilter: String? = nil,
        pbxProj: PBXProj
    ) -> PBXTargetDependency {
        let target = PBXNativeTarget.mock(
            name: name,
            productType: .application,
            pbxProj: pbxProj
        )

        let dep = PBXTargetDependency(
            name: nil,
            target: target
        )
        dep.platformFilter = platformFilter
        dep.platformFilters = platformFilters
        pbxProj.add(object: dep)
        return dep
    }

    public static func mockPackageProductDependency(
        productName: String,
        pbxProj: PBXProj
    ) -> PBXTargetDependency {
        let productRef = XCSwiftPackageProductDependency.mock(
            productName: productName,
            pbxProj: pbxProj
        )
        let dep = PBXTargetDependency(name: nil, product: productRef)
        pbxProj.add(object: dep)
        return dep
    }

    public static func mockProxyDependency(
        remoteInfo: String,
        proxyType: PBXContainerItemProxy.ProxyType,
        containerPortal: PBXContainerItemProxy.ContainerPortal,
        pbxProj: PBXProj,
        platformFilter: String? = nil,
        platformFilters: [String]? = nil,
        remoteObject: PBXObject? = nil
    ) -> PBXTargetDependency {
        let proxy = PBXContainerItemProxy(
            containerPortal: containerPortal,
            remoteGlobalID: .string("GLOBAL_ID"),
            proxyType: proxyType,
            remoteInfo: remoteInfo
        )
        pbxProj.add(object: proxy)

        if let remoteObject {
            proxy.remoteGlobalID = .object(remoteObject)
        }

        let dep = PBXTargetDependency(name: nil, target: nil, targetProxy: proxy)
        dep.platformFilter = platformFilter
        dep.platformFilters = platformFilters
        pbxProj.add(object: dep)
        return dep
    }
}

extension XCSwiftPackageProductDependency {
    public static func mock(
        productName: String,
        package: XCRemoteSwiftPackageReference? = nil,
        isPlugin: Bool = false,
        pbxProj: PBXProj
    ) -> XCSwiftPackageProductDependency {
        let dep = XCSwiftPackageProductDependency(
            productName: productName, package: package, isPlugin: isPlugin
        )
        pbxProj.add(object: dep)
        return dep
    }
}

extension PBXNativeTarget {
    public static func mock(
        name: String = "App",
        buildConfigurationList: XCConfigurationList? = nil,
        buildRules: [PBXBuildRule]? = nil,
        buildPhases: [PBXBuildPhase]? = nil,
        dependencies: [PBXTargetDependency] = [],
        productInstallPath: String? = nil,
        productType: PBXProductType = .application,
        product: PBXFileReference? = nil,
        pbxProj: PBXProj
    ) -> PBXNativeTarget {
        let resolvedProduct =
            product
                ?? PBXFileReference.mock(
                    sourceTree: .buildProductsDir,
                    explicitFileType: "wrapper.application",
                    path: "App.app",
                    lastKnownFileType: nil,
                    includeInIndex: false,
                    pbxProj: pbxProj
                )

        let resolvedBuildConfigList = buildConfigurationList ?? XCConfigurationList.mock(proj: pbxProj)
        let resolvedBuildRules = buildRules ?? [PBXBuildRule.mock(pbxProj: pbxProj)]
        let resolvedBuildPhases =
            buildPhases ?? [
                PBXSourcesBuildPhase.mock(files: [], pbxProj: pbxProj),
                PBXResourcesBuildPhase.mock(files: [], pbxProj: pbxProj),
                PBXFrameworksBuildPhase.mock(files: [], pbxProj: pbxProj),
            ]

        let target = PBXNativeTarget(
            name: name,
            buildConfigurationList: resolvedBuildConfigList,
            buildPhases: resolvedBuildPhases,
            buildRules: resolvedBuildRules,
            dependencies: dependencies,
            productInstallPath: productInstallPath,
            productName: name,
            product: resolvedProduct,
            productType: productType
        )
        pbxProj.add(object: target)
        return target
    }
}

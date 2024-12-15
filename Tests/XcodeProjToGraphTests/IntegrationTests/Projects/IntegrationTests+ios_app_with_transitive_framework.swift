import Foundation
import InlineSnapshotTesting
import Path
import Testing
import XcodeGraph
import XcodeProj
import XcodeProjToGraph
@testable import TestSupport

extension IntegrationTests {
    @Test
    func ios_app_with_transitive_framework() async throws {
        try await assertGraph {
            .ios_app_with_transitive_framework
        } name: {
            """
            - "Workspace"

            """
        } dependencies: {
            """
            ▿ 8 key/value pairs
              ▿ (2 elements)
                ▿ key: target 'AppTests'
                  ▿ target: (3 elements)
                    - name: "AppTests"
                    - path: /Fixtures/ios_app_with_transitive_framework/App
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'App'
                    ▿ target: (3 elements)
                      - name: "App"
                      - path: /Fixtures/ios_app_with_transitive_framework/App
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'AppUITests'
                  ▿ target: (3 elements)
                    - name: "AppUITests"
                    - path: /Fixtures/ios_app_with_transitive_framework/App
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'App'
                    ▿ target: (3 elements)
                      - name: "App"
                      - path: /Fixtures/ios_app_with_transitive_framework/App
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'Framework1-iOS'
                  ▿ target: (3 elements)
                    - name: "Framework1-iOS"
                    - path: /Fixtures/ios_app_with_transitive_framework/Framework1
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ framework 'Framework2.framework'
                    ▿ framework: (7 elements)
                      - path: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/iOS/Framework2.framework
                      - binaryPath: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/iOS/Framework2.framework/Framework2
                      - dsymPath: Optional<AbsolutePath>.none
                      - bcsymbolmapPaths: 0 elements
                      - linking: BinaryLinking.dynamic
                      ▿ architectures: 2 elements
                        - BinaryArchitecture.x8664
                        - BinaryArchitecture.arm64
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'Framework1-macOS'
                  ▿ target: (3 elements)
                    - name: "Framework1-macOS"
                    - path: /Fixtures/ios_app_with_transitive_framework/Framework1
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ framework 'Framework2.framework'
                    ▿ framework: (7 elements)
                      - path: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/Mac/Framework2.framework
                      - binaryPath: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/Mac/Framework2.framework/Framework2
                      - dsymPath: Optional<AbsolutePath>.none
                      - bcsymbolmapPaths: 0 elements
                      - linking: BinaryLinking.dynamic
                      ▿ architectures: 1 element
                        - BinaryArchitecture.arm64
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'Framework1Tests-iOS'
                  ▿ target: (3 elements)
                    - name: "Framework1Tests-iOS"
                    - path: /Fixtures/ios_app_with_transitive_framework/Framework1
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'Framework1-iOS'
                    ▿ target: (3 elements)
                      - name: "Framework1-iOS"
                      - path: /Fixtures/ios_app_with_transitive_framework/Framework1
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'Framework1Tests-macOS'
                  ▿ target: (3 elements)
                    - name: "Framework1Tests-macOS"
                    - path: /Fixtures/ios_app_with_transitive_framework/Framework1
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'Framework1-macOS'
                    ▿ target: (3 elements)
                      - name: "Framework1-macOS"
                      - path: /Fixtures/ios_app_with_transitive_framework/Framework1
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'StaticFramework1'
                  ▿ target: (3 elements)
                    - name: "StaticFramework1"
                    - path: /Fixtures/ios_app_with_transitive_framework/StaticFramework1
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ framework 'Framework2.framework'
                    ▿ framework: (7 elements)
                      - path: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/iOS/Framework2.framework
                      - binaryPath: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/iOS/Framework2.framework/Framework2
                      - dsymPath: Optional<AbsolutePath>.none
                      - bcsymbolmapPaths: 0 elements
                      - linking: BinaryLinking.dynamic
                      ▿ architectures: 2 elements
                        - BinaryArchitecture.x8664
                        - BinaryArchitecture.arm64
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'StaticFramework1Tests'
                  ▿ target: (3 elements)
                    - name: "StaticFramework1Tests"
                    - path: /Fixtures/ios_app_with_transitive_framework/StaticFramework1
                    - status: LinkingStatus.required
                ▿ value: 2 members
                  ▿ framework 'Framework2.framework'
                    ▿ framework: (7 elements)
                      - path: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/iOS/Framework2.framework
                      - binaryPath: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/iOS/Framework2.framework/Framework2
                      - dsymPath: Optional<AbsolutePath>.none
                      - bcsymbolmapPaths: 0 elements
                      - linking: BinaryLinking.dynamic
                      ▿ architectures: 2 elements
                        - BinaryArchitecture.x8664
                        - BinaryArchitecture.arm64
                      - status: LinkingStatus.required
                  ▿ target 'StaticFramework1'
                    ▿ target: (3 elements)
                      - name: "StaticFramework1"
                      - path: /Fixtures/ios_app_with_transitive_framework/StaticFramework1
                      - status: LinkingStatus.required

            """
        } dependencyConditions: {
            """
            - 0 key/value pairs

            """
        } packages: {
            """
            - 0 key/value pairs

            """
        } workspace: {
            """
            ▿ Workspace
              - additionalFiles: 0 elements
              ▿ generationOptions: GenerationOptions
                ▿ autogeneratedWorkspaceSchemes: AutogeneratedWorkspaceSchemes
                  ▿ enabled: (5 elements)
                    - codeCoverageMode: CodeCoverageMode.disabled
                    ▿ testingOptions: TestingOptions
                      - rawValue: 0
                    - testLanguage: Optional<String>.none
                    - testRegion: Optional<String>.none
                    - testScreenCaptureFormat: Optional<ScreenCaptureFormat>.none
                ▿ enableAutomaticXcodeSchemes: Optional<Bool>
                  - some: false
                - lastXcodeUpgradeCheck: Optional<Version>.none
                - renderMarkdownReadme: false
              - ideTemplateMacros: Optional<IDETemplateMacros>.none
              - name: "Workspace"
              - path: /Fixtures/ios_app_with_transitive_framework
              ▿ projects: 3 elements
                - /Fixtures/ios_app_with_transitive_framework/App/MainApp.xcodeproj
                - /Fixtures/ios_app_with_transitive_framework/Framework1/Framework1.xcodeproj
                - /Fixtures/ios_app_with_transitive_framework/StaticFramework1/StaticFramework1.xcodeproj
              - schemes: 0 elements
              - xcWorkspacePath: /Fixtures/ios_app_with_transitive_framework/Workspace.xcworkspace

            """
        } projects: {
            """
            ▿ 3 key/value pairs
              ▿ (2 elements)
                - key: /Fixtures/ios_app_with_transitive_framework/App/MainApp.xcodeproj
                ▿ value: MainApp
                  - path: /Fixtures/ios_app_with_transitive_framework/App
                  - sourceRootPath: /Fixtures/ios_app_with_transitive_framework/App
                  - xcodeProjPath: /Fixtures/ios_app_with_transitive_framework/App
                  - name: "MainApp"
                  - organizationName: Optional<String>.none
                  - classPrefix: Optional<String>.none
                  ▿ defaultKnownRegions: Optional<Array<String>>
                    ▿ some: 2 elements
                      - "Base"
                      - "en"
                  ▿ developmentRegion: Optional<String>
                    - some: "en"
                  ▿ options: Options
                    - automaticSchemesOptions: AutomaticSchemesOptions.disabled
                    - disableBundleAccessors: false
                    - disableShowEnvironmentVarsInScriptPhases: false
                    - disableSynthesizedResourceAccessors: false
                    ▿ textSettings: TextSettings
                      - indentWidth: Optional<UInt>.none
                      - tabWidth: Optional<UInt>.none
                      - usesTabs: Optional<Bool>.none
                      - wrapsLines: Optional<Bool>.none
                  ▿ targets: 3 key/value pairs
                    ▿ (2 elements)
                      - key: "App"
                      ▿ value: Target
                        - additionalFiles: 0 elements
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.App"
                        ▿ copyFiles: 1 element
                          ▿ CopyFilesAction
                            - destination: Destination.frameworks
                            - files: 0 elements
                            - name: "Embed Frameworks"
                            - subpath: Optional<String>.none
                        - coreDataModels: 0 elements
                        - dependencies: 0 elements
                        ▿ deploymentTargets: DeploymentTargets
                          - iOS: Optional<String>.none
                          - macOS: Optional<String>.none
                          - tvOS: Optional<String>.none
                          - visionOS: Optional<String>.none
                          - watchOS: Optional<String>.none
                        - destinations: 0 members
                        - entitlements: Optional<Entitlements>.none
                        - environmentVariables: 0 key/value pairs
                        ▿ filesGroup: ProjectGroup
                          ▿ group: (1 element)
                            - name: "MainGroup"
                        - headers: Optional<Headers>.none
                        - infoPlist: Optional<InfoPlist>.none
                        - launchArguments: 0 elements
                        - mergeable: false
                        - mergedBinaryType: MergedBinaryType.disabled
                        ▿ metadata: TargetMetadata
                          - tags: 0 members
                        - name: "App"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: application
                        - productName: "App"
                        - prune: false
                        - rawScriptBuildPhases: 0 elements
                        ▿ resources: ResourceFileElements
                          - privacyManifest: Optional<PrivacyManifest>.none
                          - resources: 0 elements
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 1 element
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_transitive_framework/App/Sources/AppDelegate.swift
                    ▿ (2 elements)
                      - key: "AppTests"
                      ▿ value: Target
                        - additionalFiles: 0 elements
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.AppTests"
                        ▿ copyFiles: 1 element
                          ▿ CopyFilesAction
                            - destination: Destination.frameworks
                            - files: 0 elements
                            - name: "Embed Frameworks"
                            - subpath: Optional<String>.none
                        - coreDataModels: 0 elements
                        ▿ dependencies: 1 element
                          ▿ TargetDependency
                            ▿ target: (3 elements)
                              - name: "App"
                              - status: LinkingStatus.required
                              - condition: Optional<PlatformCondition>.none
                        ▿ deploymentTargets: DeploymentTargets
                          - iOS: Optional<String>.none
                          - macOS: Optional<String>.none
                          - tvOS: Optional<String>.none
                          - visionOS: Optional<String>.none
                          - watchOS: Optional<String>.none
                        - destinations: 0 members
                        - entitlements: Optional<Entitlements>.none
                        - environmentVariables: 0 key/value pairs
                        ▿ filesGroup: ProjectGroup
                          ▿ group: (1 element)
                            - name: "MainGroup"
                        - headers: Optional<Headers>.none
                        - infoPlist: Optional<InfoPlist>.none
                        - launchArguments: 0 elements
                        - mergeable: false
                        - mergedBinaryType: MergedBinaryType.disabled
                        ▿ metadata: TargetMetadata
                          - tags: 0 members
                        - name: "AppTests"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: unit tests
                        - productName: "AppTests"
                        - prune: false
                        - rawScriptBuildPhases: 0 elements
                        ▿ resources: ResourceFileElements
                          - privacyManifest: Optional<PrivacyManifest>.none
                          - resources: 0 elements
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 1 element
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_transitive_framework/App/Tests/AppDelegateTests.swift
                    ▿ (2 elements)
                      - key: "AppUITests"
                      ▿ value: Target
                        - additionalFiles: 0 elements
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.AppUITests"
                        ▿ copyFiles: 1 element
                          ▿ CopyFilesAction
                            - destination: Destination.frameworks
                            - files: 0 elements
                            - name: "Embed Frameworks"
                            - subpath: Optional<String>.none
                        - coreDataModels: 0 elements
                        ▿ dependencies: 1 element
                          ▿ TargetDependency
                            ▿ target: (3 elements)
                              - name: "App"
                              - status: LinkingStatus.required
                              - condition: Optional<PlatformCondition>.none
                        ▿ deploymentTargets: DeploymentTargets
                          - iOS: Optional<String>.none
                          - macOS: Optional<String>.none
                          - tvOS: Optional<String>.none
                          - visionOS: Optional<String>.none
                          - watchOS: Optional<String>.none
                        - destinations: 0 members
                        - entitlements: Optional<Entitlements>.none
                        - environmentVariables: 0 key/value pairs
                        ▿ filesGroup: ProjectGroup
                          ▿ group: (1 element)
                            - name: "MainGroup"
                        - headers: Optional<Headers>.none
                        - infoPlist: Optional<InfoPlist>.none
                        - launchArguments: 0 elements
                        - mergeable: false
                        - mergedBinaryType: MergedBinaryType.disabled
                        ▿ metadata: TargetMetadata
                          - tags: 0 members
                        - name: "AppUITests"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: ui tests
                        - productName: "AppUITests"
                        - prune: false
                        - rawScriptBuildPhases: 0 elements
                        ▿ resources: ResourceFileElements
                          - privacyManifest: Optional<PrivacyManifest>.none
                          - resources: 0 elements
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 1 element
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_transitive_framework/App/UITests/AppUITest.swift
                  - packages: 0 elements
                  - schemes: 0 elements
                  ▿ settings: Settings
                    - base: 0 key/value pairs
                    - baseDebug: 0 key/value pairs
                    - configurations: 0 key/value pairs
                    ▿ defaultSettings: DefaultSettings
                      ▿ recommended: (1 element)
                        - excluding: 0 members
                  ▿ filesGroup: ProjectGroup
                    ▿ group: (1 element)
                      - name: "Project"
                  - additionalFiles: 0 elements
                  - ideTemplateMacros: Optional<IDETemplateMacros>.none
                  - resourceSynthesizers: 0 elements
                  - lastUpgradeCheck: Optional<Version>.none
                  - type: local project
              ▿ (2 elements)
                - key: /Fixtures/ios_app_with_transitive_framework/Framework1/Framework1.xcodeproj
                ▿ value: Framework1
                  - path: /Fixtures/ios_app_with_transitive_framework/Framework1
                  - sourceRootPath: /Fixtures/ios_app_with_transitive_framework/Framework1
                  - xcodeProjPath: /Fixtures/ios_app_with_transitive_framework/Framework1
                  - name: "Framework1"
                  - organizationName: Optional<String>.none
                  - classPrefix: Optional<String>.none
                  ▿ defaultKnownRegions: Optional<Array<String>>
                    ▿ some: 2 elements
                      - "Base"
                      - "en"
                  ▿ developmentRegion: Optional<String>
                    - some: "en"
                  ▿ options: Options
                    - automaticSchemesOptions: AutomaticSchemesOptions.disabled
                    - disableBundleAccessors: false
                    - disableShowEnvironmentVarsInScriptPhases: false
                    - disableSynthesizedResourceAccessors: false
                    ▿ textSettings: TextSettings
                      - indentWidth: Optional<UInt>.none
                      - tabWidth: Optional<UInt>.none
                      - usesTabs: Optional<Bool>.none
                      - wrapsLines: Optional<Bool>.none
                  ▿ targets: 4 key/value pairs
                    ▿ (2 elements)
                      - key: "Framework1-iOS"
                      ▿ value: Target
                        - additionalFiles: 0 elements
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.Framework1"
                        ▿ copyFiles: 1 element
                          ▿ CopyFilesAction
                            - destination: Destination.frameworks
                            - files: 0 elements
                            - name: "Embed Frameworks"
                            - subpath: Optional<String>.none
                        - coreDataModels: 0 elements
                        ▿ dependencies: 1 element
                          ▿ TargetDependency
                            ▿ framework: (3 elements)
                              - path: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/iOS/Framework2.framework
                              - status: LinkingStatus.required
                              - condition: Optional<PlatformCondition>.none
                        ▿ deploymentTargets: DeploymentTargets
                          - iOS: Optional<String>.none
                          - macOS: Optional<String>.none
                          - tvOS: Optional<String>.none
                          - visionOS: Optional<String>.none
                          - watchOS: Optional<String>.none
                        - destinations: 0 members
                        - entitlements: Optional<Entitlements>.none
                        - environmentVariables: 0 key/value pairs
                        ▿ filesGroup: ProjectGroup
                          ▿ group: (1 element)
                            - name: "MainGroup"
                        - headers: Optional<Headers>.none
                        - infoPlist: Optional<InfoPlist>.none
                        - launchArguments: 0 elements
                        - mergeable: false
                        - mergedBinaryType: MergedBinaryType.disabled
                        ▿ metadata: TargetMetadata
                          - tags: 0 members
                        - name: "Framework1-iOS"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: dynamic framework
                        - productName: "Framework1"
                        - prune: false
                        - rawScriptBuildPhases: 0 elements
                        ▿ resources: ResourceFileElements
                          - privacyManifest: Optional<PrivacyManifest>.none
                          - resources: 0 elements
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 1 element
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_transitive_framework/Framework1/Sources/Framework1File.swift
                    ▿ (2 elements)
                      - key: "Framework1-macOS"
                      ▿ value: Target
                        - additionalFiles: 0 elements
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.Framework1"
                        ▿ copyFiles: 1 element
                          ▿ CopyFilesAction
                            - destination: Destination.frameworks
                            - files: 0 elements
                            - name: "Embed Frameworks"
                            - subpath: Optional<String>.none
                        - coreDataModels: 0 elements
                        ▿ dependencies: 1 element
                          ▿ TargetDependency
                            ▿ framework: (3 elements)
                              - path: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/Mac/Framework2.framework
                              - status: LinkingStatus.required
                              - condition: Optional<PlatformCondition>.none
                        ▿ deploymentTargets: DeploymentTargets
                          - iOS: Optional<String>.none
                          - macOS: Optional<String>.none
                          - tvOS: Optional<String>.none
                          - visionOS: Optional<String>.none
                          - watchOS: Optional<String>.none
                        - destinations: 0 members
                        - entitlements: Optional<Entitlements>.none
                        - environmentVariables: 0 key/value pairs
                        ▿ filesGroup: ProjectGroup
                          ▿ group: (1 element)
                            - name: "MainGroup"
                        - headers: Optional<Headers>.none
                        - infoPlist: Optional<InfoPlist>.none
                        - launchArguments: 0 elements
                        - mergeable: false
                        - mergedBinaryType: MergedBinaryType.disabled
                        ▿ metadata: TargetMetadata
                          - tags: 0 members
                        - name: "Framework1-macOS"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: dynamic framework
                        - productName: "Framework1"
                        - prune: false
                        - rawScriptBuildPhases: 0 elements
                        ▿ resources: ResourceFileElements
                          - privacyManifest: Optional<PrivacyManifest>.none
                          - resources: 0 elements
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 1 element
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_transitive_framework/Framework1/Sources/Framework1File.swift
                    ▿ (2 elements)
                      - key: "Framework1Tests-iOS"
                      ▿ value: Target
                        - additionalFiles: 0 elements
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.Framework1Tests"
                        ▿ copyFiles: 1 element
                          ▿ CopyFilesAction
                            - destination: Destination.frameworks
                            - files: 0 elements
                            - name: "Embed Frameworks"
                            - subpath: Optional<String>.none
                        - coreDataModels: 0 elements
                        ▿ dependencies: 1 element
                          ▿ TargetDependency
                            ▿ target: (3 elements)
                              - name: "Framework1-iOS"
                              - status: LinkingStatus.required
                              - condition: Optional<PlatformCondition>.none
                        ▿ deploymentTargets: DeploymentTargets
                          - iOS: Optional<String>.none
                          - macOS: Optional<String>.none
                          - tvOS: Optional<String>.none
                          - visionOS: Optional<String>.none
                          - watchOS: Optional<String>.none
                        - destinations: 0 members
                        - entitlements: Optional<Entitlements>.none
                        - environmentVariables: 0 key/value pairs
                        ▿ filesGroup: ProjectGroup
                          ▿ group: (1 element)
                            - name: "MainGroup"
                        - headers: Optional<Headers>.none
                        - infoPlist: Optional<InfoPlist>.none
                        - launchArguments: 0 elements
                        - mergeable: false
                        - mergedBinaryType: MergedBinaryType.disabled
                        ▿ metadata: TargetMetadata
                          - tags: 0 members
                        - name: "Framework1Tests-iOS"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: unit tests
                        - productName: "Framework1Tests_iOS"
                        - prune: false
                        - rawScriptBuildPhases: 0 elements
                        ▿ resources: ResourceFileElements
                          - privacyManifest: Optional<PrivacyManifest>.none
                          - resources: 0 elements
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 1 element
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_transitive_framework/Framework1/Tests/Framework1FileTests.swift
                    ▿ (2 elements)
                      - key: "Framework1Tests-macOS"
                      ▿ value: Target
                        - additionalFiles: 0 elements
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.Framework1Tests"
                        ▿ copyFiles: 1 element
                          ▿ CopyFilesAction
                            - destination: Destination.frameworks
                            - files: 0 elements
                            - name: "Embed Frameworks"
                            - subpath: Optional<String>.none
                        - coreDataModels: 0 elements
                        ▿ dependencies: 1 element
                          ▿ TargetDependency
                            ▿ target: (3 elements)
                              - name: "Framework1-macOS"
                              - status: LinkingStatus.required
                              - condition: Optional<PlatformCondition>.none
                        ▿ deploymentTargets: DeploymentTargets
                          - iOS: Optional<String>.none
                          - macOS: Optional<String>.none
                          - tvOS: Optional<String>.none
                          - visionOS: Optional<String>.none
                          - watchOS: Optional<String>.none
                        - destinations: 0 members
                        - entitlements: Optional<Entitlements>.none
                        - environmentVariables: 0 key/value pairs
                        ▿ filesGroup: ProjectGroup
                          ▿ group: (1 element)
                            - name: "MainGroup"
                        - headers: Optional<Headers>.none
                        - infoPlist: Optional<InfoPlist>.none
                        - launchArguments: 0 elements
                        - mergeable: false
                        - mergedBinaryType: MergedBinaryType.disabled
                        ▿ metadata: TargetMetadata
                          - tags: 0 members
                        - name: "Framework1Tests-macOS"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: unit tests
                        - productName: "Framework1Tests_macOS"
                        - prune: false
                        - rawScriptBuildPhases: 0 elements
                        ▿ resources: ResourceFileElements
                          - privacyManifest: Optional<PrivacyManifest>.none
                          - resources: 0 elements
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 1 element
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_transitive_framework/Framework1/Tests/Framework1FileTests.swift
                  - packages: 0 elements
                  - schemes: 0 elements
                  ▿ settings: Settings
                    - base: 0 key/value pairs
                    - baseDebug: 0 key/value pairs
                    - configurations: 0 key/value pairs
                    ▿ defaultSettings: DefaultSettings
                      ▿ recommended: (1 element)
                        - excluding: 0 members
                  ▿ filesGroup: ProjectGroup
                    ▿ group: (1 element)
                      - name: "Project"
                  - additionalFiles: 0 elements
                  - ideTemplateMacros: Optional<IDETemplateMacros>.none
                  - resourceSynthesizers: 0 elements
                  - lastUpgradeCheck: Optional<Version>.none
                  - type: local project
              ▿ (2 elements)
                - key: /Fixtures/ios_app_with_transitive_framework/StaticFramework1/StaticFramework1.xcodeproj
                ▿ value: StaticFramework1
                  - path: /Fixtures/ios_app_with_transitive_framework/StaticFramework1
                  - sourceRootPath: /Fixtures/ios_app_with_transitive_framework/StaticFramework1
                  - xcodeProjPath: /Fixtures/ios_app_with_transitive_framework/StaticFramework1
                  - name: "StaticFramework1"
                  - organizationName: Optional<String>.none
                  - classPrefix: Optional<String>.none
                  ▿ defaultKnownRegions: Optional<Array<String>>
                    ▿ some: 2 elements
                      - "Base"
                      - "en"
                  ▿ developmentRegion: Optional<String>
                    - some: "en"
                  ▿ options: Options
                    - automaticSchemesOptions: AutomaticSchemesOptions.disabled
                    - disableBundleAccessors: false
                    - disableShowEnvironmentVarsInScriptPhases: false
                    - disableSynthesizedResourceAccessors: false
                    ▿ textSettings: TextSettings
                      - indentWidth: Optional<UInt>.none
                      - tabWidth: Optional<UInt>.none
                      - usesTabs: Optional<Bool>.none
                      - wrapsLines: Optional<Bool>.none
                  ▿ targets: 2 key/value pairs
                    ▿ (2 elements)
                      - key: "StaticFramework1"
                      ▿ value: Target
                        - additionalFiles: 0 elements
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.StaticFramework1"
                        ▿ copyFiles: 1 element
                          ▿ CopyFilesAction
                            - destination: Destination.frameworks
                            - files: 0 elements
                            - name: "Embed Frameworks"
                            - subpath: Optional<String>.none
                        - coreDataModels: 0 elements
                        ▿ dependencies: 1 element
                          ▿ TargetDependency
                            ▿ framework: (3 elements)
                              - path: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/iOS/Framework2.framework
                              - status: LinkingStatus.required
                              - condition: Optional<PlatformCondition>.none
                        ▿ deploymentTargets: DeploymentTargets
                          - iOS: Optional<String>.none
                          - macOS: Optional<String>.none
                          - tvOS: Optional<String>.none
                          - visionOS: Optional<String>.none
                          - watchOS: Optional<String>.none
                        - destinations: 0 members
                        - entitlements: Optional<Entitlements>.none
                        - environmentVariables: 0 key/value pairs
                        ▿ filesGroup: ProjectGroup
                          ▿ group: (1 element)
                            - name: "MainGroup"
                        - headers: Optional<Headers>.none
                        - infoPlist: Optional<InfoPlist>.none
                        - launchArguments: 0 elements
                        - mergeable: false
                        - mergedBinaryType: MergedBinaryType.disabled
                        ▿ metadata: TargetMetadata
                          - tags: 0 members
                        - name: "StaticFramework1"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: dynamic framework
                        - productName: "StaticFramework1"
                        - prune: false
                        - rawScriptBuildPhases: 0 elements
                        ▿ resources: ResourceFileElements
                          - privacyManifest: Optional<PrivacyManifest>.none
                          - resources: 0 elements
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 1 element
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_transitive_framework/StaticFramework1/Sources/Framework1File.swift
                    ▿ (2 elements)
                      - key: "StaticFramework1Tests"
                      ▿ value: Target
                        - additionalFiles: 0 elements
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.StaticFramework1Tests"
                        ▿ copyFiles: 1 element
                          ▿ CopyFilesAction
                            - destination: Destination.frameworks
                            - files: 0 elements
                            - name: "Embed Frameworks"
                            - subpath: Optional<String>.none
                        - coreDataModels: 0 elements
                        ▿ dependencies: 2 elements
                          ▿ TargetDependency
                            ▿ framework: (3 elements)
                              - path: /Fixtures/ios_app_with_transitive_framework/Framework2/prebuilt/iOS/Framework2.framework
                              - status: LinkingStatus.required
                              - condition: Optional<PlatformCondition>.none
                          ▿ TargetDependency
                            ▿ target: (3 elements)
                              - name: "StaticFramework1"
                              - status: LinkingStatus.required
                              - condition: Optional<PlatformCondition>.none
                        ▿ deploymentTargets: DeploymentTargets
                          - iOS: Optional<String>.none
                          - macOS: Optional<String>.none
                          - tvOS: Optional<String>.none
                          - visionOS: Optional<String>.none
                          - watchOS: Optional<String>.none
                        - destinations: 0 members
                        - entitlements: Optional<Entitlements>.none
                        - environmentVariables: 0 key/value pairs
                        ▿ filesGroup: ProjectGroup
                          ▿ group: (1 element)
                            - name: "MainGroup"
                        - headers: Optional<Headers>.none
                        - infoPlist: Optional<InfoPlist>.none
                        - launchArguments: 0 elements
                        - mergeable: false
                        - mergedBinaryType: MergedBinaryType.disabled
                        ▿ metadata: TargetMetadata
                          - tags: 0 members
                        - name: "StaticFramework1Tests"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: unit tests
                        - productName: "StaticFramework1Tests"
                        - prune: false
                        - rawScriptBuildPhases: 0 elements
                        ▿ resources: ResourceFileElements
                          - privacyManifest: Optional<PrivacyManifest>.none
                          - resources: 0 elements
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 1 element
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_transitive_framework/StaticFramework1/Tests/Framework1FileTests.swift
                  - packages: 0 elements
                  - schemes: 0 elements
                  ▿ settings: Settings
                    - base: 0 key/value pairs
                    - baseDebug: 0 key/value pairs
                    - configurations: 0 key/value pairs
                    ▿ defaultSettings: DefaultSettings
                      ▿ recommended: (1 element)
                        - excluding: 0 members
                  ▿ filesGroup: ProjectGroup
                    ▿ group: (1 element)
                      - name: "Project"
                  - additionalFiles: 0 elements
                  - ideTemplateMacros: Optional<IDETemplateMacros>.none
                  - resourceSynthesizers: 0 elements
                  - lastUpgradeCheck: Optional<Version>.none
                  - type: local project

            """
        }
    }
}

import Foundation
import InlineSnapshotTesting
import Path
import Testing
import XcodeGraph
import XcodeProj
import XcodeProjToGraph

@testable import TestSupport

extension IntegrationTests {
    @Test("Maps an iOS workspace using microfeature architecture with static linking into the correct graph")
    func iosWorkspaceWithMicrofeatureArchitectureStaticLinking() async throws {
        try await assertGraph {
            .iosWorkspaceWithMicrofeatureArchitectureStaticLinking
        } name: {
            """
            - "Workspace"

            """
        } dependencies: {
            """
            ▿ 6 key/value pairs
              ▿ (2 elements)
                ▿ key: target 'CoreTests'
                  ▿ target: (3 elements)
                    - name: "CoreTests"
                    - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'Core'
                    ▿ target: (3 elements)
                      - name: "Core"
                      - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'DataTests'
                  ▿ target: (3 elements)
                    - name: "DataTests"
                    - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'Data'
                    ▿ target: (3 elements)
                      - name: "Data"
                      - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'FeatureContractsTests'
                  ▿ target: (3 elements)
                    - name: "FeatureContractsTests"
                    - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'FeatureContracts'
                    ▿ target: (3 elements)
                      - name: "FeatureContracts"
                      - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'FrameworkATests'
                  ▿ target: (3 elements)
                    - name: "FrameworkATests"
                    - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'FrameworkA'
                    ▿ target: (3 elements)
                      - name: "FrameworkA"
                      - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'StaticAppTests'
                  ▿ target: (3 elements)
                    - name: "StaticAppTests"
                    - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'StaticApp'
                    ▿ target: (3 elements)
                      - name: "StaticApp"
                      - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp
                      - status: LinkingStatus.required
              ▿ (2 elements)
                ▿ key: target 'UIComponentsTests'
                  ▿ target: (3 elements)
                    - name: "UIComponentsTests"
                    - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'UIComponents'
                    ▿ target: (3 elements)
                      - name: "UIComponents"
                      - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework
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
              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking
              ▿ projects: 6 elements
                - /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework/Core.xcodeproj
                - /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework/Data.xcodeproj
                - /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework/FrameworkA.xcodeproj
                - /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/FeatureContracts.xcodeproj
                - /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework/UIComponents.xcodeproj
                - /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp/StaticApp.xcodeproj
              - schemes: 0 elements
              - xcWorkspacePath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Workspace.xcworkspace

            """
        } projects: {
            """
            ▿ 6 key/value pairs
              ▿ (2 elements)
                - key: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework/Core.xcodeproj
                ▿ value: Core
                  - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework
                  - sourceRootPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework
                  - xcodeProjPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework
                  - name: "Core"
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
                      - key: "Core"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework/Tests.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework/Tests/CoreClassTests.swift
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.Core"
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
                        - name: "Core"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: dynamic framework
                        - productName: "Core"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework/Sources/CoreClass.swift
                    ▿ (2 elements)
                      - key: "CoreTests"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework/Sources/CoreClass.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework/Tests.plist
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.CoreTests"
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
                              - name: "Core"
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
                        - name: "CoreTests"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: unit tests
                        - productName: "CoreTests"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/CoreFramework/Tests/CoreClassTests.swift
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
                - key: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework/Data.xcodeproj
                ▿ value: Data
                  - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework
                  - sourceRootPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework
                  - xcodeProjPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework
                  - name: "Data"
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
                      - key: "Data"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework/Tests.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework/Tests/FrameworkATests.swift
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.Data"
                        ▿ copyFiles: 2 elements
                          ▿ CopyFilesAction
                            - destination: Destination.productsDirectory
                            - files: 0 elements
                            - name: "Dependencies"
                            - subpath: Optional<String>.none
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
                        - name: "Data"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: dynamic framework
                        - productName: "Data"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework/Sources/DataClass.swift
                    ▿ (2 elements)
                      - key: "DataTests"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework/Sources/DataClass.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework/Tests.plist
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.DataFrameworkTests"
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
                              - name: "Data"
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
                        - name: "DataTests"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: unit tests
                        - productName: "DataTests"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/DataFramework/Tests/FrameworkATests.swift
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
                - key: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework/FrameworkA.xcodeproj
                ▿ value: FrameworkA
                  - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework
                  - sourceRootPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework
                  - xcodeProjPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework
                  - name: "FrameworkA"
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
                      - key: "FrameworkA"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework/Tests.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework/Tests/FrameworkATests.swift
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.FrameworkA"
                        ▿ copyFiles: 2 elements
                          ▿ CopyFilesAction
                            - destination: Destination.productsDirectory
                            - files: 0 elements
                            - name: "Dependencies"
                            - subpath: Optional<String>.none
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
                        - name: "FrameworkA"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: dynamic framework
                        - productName: "FrameworkA"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework/Sources/FrameworkA.swift
                    ▿ (2 elements)
                      - key: "FrameworkATests"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework/Sources/FrameworkA.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework/Tests.plist
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.FrameworkATests"
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
                              - name: "FrameworkA"
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
                        - name: "FrameworkATests"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: unit tests
                        - productName: "FrameworkATests"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureAFramework/Tests/FrameworkATests.swift
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
                - key: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/FeatureContracts.xcodeproj
                ▿ value: FeatureContracts
                  - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts
                  - sourceRootPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts
                  - xcodeProjPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts
                  - name: "FeatureContracts"
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
                      - key: "FeatureContracts"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/Tests.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/Tests/FrameworkAContractTests.swift
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.FeatureContracts"
                        ▿ copyFiles: 2 elements
                          ▿ CopyFilesAction
                            - destination: Destination.productsDirectory
                            - files: 0 elements
                            - name: "Dependencies"
                            - subpath: Optional<String>.none
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
                        - name: "FeatureContracts"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: dynamic framework
                        - productName: "FeatureContracts"
                        - prune: false
                        - rawScriptBuildPhases: 0 elements
                        ▿ resources: ResourceFileElements
                          - privacyManifest: Optional<PrivacyManifest>.none
                          - resources: 0 elements
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 2 elements
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/Sources/FeatureAContract.swift
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/Sources/FeatureBContract.swift
                    ▿ (2 elements)
                      - key: "FeatureContractsTests"
                      ▿ value: Target
                        ▿ additionalFiles: 4 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/Sources/FeatureAContract.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/Sources/FeatureBContract.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/Tests.plist
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.FeatureContractsTests"
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
                              - name: "FeatureContracts"
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
                        - name: "FeatureContractsTests"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: unit tests
                        - productName: "FeatureContractsTests"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/FeatureContracts/Tests/FrameworkAContractTests.swift
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
                - key: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework/UIComponents.xcodeproj
                ▿ value: UIComponents
                  - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework
                  - sourceRootPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework
                  - xcodeProjPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework
                  - name: "UIComponents"
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
                      - key: "UIComponents"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework/Tests.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework/Tests/UIComponentATests.swift
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.UIComponents"
                        ▿ copyFiles: 2 elements
                          ▿ CopyFilesAction
                            - destination: Destination.productsDirectory
                            - files: 0 elements
                            - name: "Dependencies"
                            - subpath: Optional<String>.none
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
                        - name: "UIComponents"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: dynamic framework
                        - productName: "UIComponents"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework/Sources/UIComponentA.swift
                    ▿ (2 elements)
                      - key: "UIComponentsTests"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework/Sources/UIComponentA.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework/Tests.plist
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.UIComponentsTests"
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
                              - name: "UIComponents"
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
                        - name: "UIComponentsTests"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: unit tests
                        - productName: "UIComponentsTests"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/Frameworks/UIComponentsFramework/Tests/UIComponentATests.swift
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
                - key: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp/StaticApp.xcodeproj
                ▿ value: StaticApp
                  - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp
                  - sourceRootPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp
                  - xcodeProjPath: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp
                  - name: "StaticApp"
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
                      - key: "StaticApp"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp/Tests.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp/Tests/AppTests.swift
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.StaticApp"
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
                        - name: "StaticApp"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: application
                        - productName: "StaticApp"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp/Sources/AppDelegate.swift
                    ▿ (2 elements)
                      - key: "StaticAppTests"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp/Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp/Sources/AppDelegate.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp/Tests.plist
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.StaticAppTests"
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
                              - name: "StaticApp"
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
                        - name: "StaticAppTests"
                        - onDemandResourcesTags: Optional<OnDemandResourcesTags>.none
                        - playgrounds: 0 elements
                        - product: unit tests
                        - productName: "StaticAppTests"
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
                            - path: /Fixtures/ios_workspace_with_microfeature_architecture_static_linking/StaticApp/Tests/AppTests.swift
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

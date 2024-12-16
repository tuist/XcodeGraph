import Foundation
import InlineSnapshotTesting
import Path
import Testing
import XcodeGraph
import XcodeProj
import XcodeProjToGraph

@testable import TestSupport

extension IntegrationTests {
    @Test("Maps an iOS app with SPM dependencies into the correct graph")
    func iosAppWithSpmDependencies() async throws {
        try await assertGraph {
            .iosAppWithSpmDependencies
        } name: {
            """
            - "App"

            """
        } dependencies: {
            """
            ▿ 1 key/value pair
              ▿ (2 elements)
                ▿ key: target 'AppTests'
                  ▿ target: (3 elements)
                    - name: "AppTests"
                    - path: /Fixtures/ios_app_with_spm_dependencies
                    - status: LinkingStatus.required
                ▿ value: 1 member
                  ▿ target 'App'
                    ▿ target: (3 elements)
                      - name: "App"
                      - path: /Fixtures/ios_app_with_spm_dependencies
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
              - name: "App"
              - path: /Fixtures/ios_app_with_spm_dependencies
              ▿ projects: 8 elements
                - /Fixtures/ios_app_with_spm_dependencies/App.xcodeproj
                - /Fixtures/ios_app_with_spm_dependencies/Tuist/.build/tuist-derived/BigInt/BigInt.xcodeproj
                - /Fixtures/ios_app_with_spm_dependencies/Tuist/.build/tuist-derived/KSCrash/KSCrash.xcodeproj
                - /Fixtures/ios_app_with_spm_dependencies/Tuist/.build/tuist-derived/Mobile Buy SDK/Mobile Buy SDK.xcodeproj
                - /Fixtures/ios_app_with_spm_dependencies/Tuist/.build/tuist-derived/jwt-kit/jwt-kit.xcodeproj
                - /Fixtures/ios_app_with_spm_dependencies/Tuist/.build/tuist-derived/swift-asn1/swift-asn1.xcodeproj
                - /Fixtures/ios_app_with_spm_dependencies/Tuist/.build/tuist-derived/swift-certificates/swift-certificates.xcodeproj
                - /Fixtures/ios_app_with_spm_dependencies/Tuist/.build/tuist-derived/swift-crypto/swift-crypto.xcodeproj
              - schemes: 0 elements
              - xcWorkspacePath: /Fixtures/ios_app_with_spm_dependencies/App.xcworkspace

            """
        } projects: {
            """
            ▿ 1 key/value pair
              ▿ (2 elements)
                - key: /Fixtures/ios_app_with_spm_dependencies/App.xcodeproj
                ▿ value: App
                  - path: /Fixtures/ios_app_with_spm_dependencies
                  - sourceRootPath: /Fixtures/ios_app_with_spm_dependencies
                  - xcodeProjPath: /Fixtures/ios_app_with_spm_dependencies
                  - name: "App"
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
                      - key: "App"
                      ▿ value: Target
                        ▿ additionalFiles: 3 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/AppTests/AppTests.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/Derived/InfoPlists/App-Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/Derived/InfoPlists/AppTests-Info.plist
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.app"
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
                          ▿ iOS: Optional<String>
                            - some: "16.0"
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
                          ▿ resources: 2 elements
                            ▿ ResourceFileElement
                              ▿ file: (3 elements)
                                - path: /Fixtures/ios_app_with_spm_dependencies/App/Resources/Assets.xcassets
                                - tags: 0 elements
                                - inclusionCondition: Optional<PlatformCondition>.none
                            ▿ ResourceFileElement
                              ▿ file: (3 elements)
                                - path: /Fixtures/ios_app_with_spm_dependencies/App/Resources/Preview Content/Preview Assets.xcassets
                                - tags: 0 elements
                                - inclusionCondition: Optional<PlatformCondition>.none
                        - scripts: 0 elements
                        - settings: Optional<Settings>.none
                        ▿ sources: 4 elements
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_spm_dependencies/App/Sources/AppApp.swift
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_spm_dependencies/App/Sources/ContentView.swift
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_spm_dependencies/Derived/Sources/TuistAssets+App.swift
                          ▿ SourceFile
                            - codeGen: Optional<FileCodeGen>.none
                            - compilationCondition: Optional<PlatformCondition>.none
                            - compilerFlags: Optional<String>.none
                            - contentHash: Optional<String>.none
                            - path: /Fixtures/ios_app_with_spm_dependencies/Derived/Sources/TuistBundle+App.swift
                    ▿ (2 elements)
                      - key: "AppTests"
                      ▿ value: Target
                        ▿ additionalFiles: 8 elements
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/App/Resources/Assets.xcassets
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/App/Resources/Preview Content/Preview Assets.xcassets
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/App/Sources/AppApp.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/App/Sources/ContentView.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/Derived/InfoPlists/App-Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/Derived/InfoPlists/AppTests-Info.plist
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/Derived/Sources/TuistAssets+App.swift
                          ▿ FileElement
                            ▿ file: (1 element)
                              - path: /Fixtures/ios_app_with_spm_dependencies/Derived/Sources/TuistBundle+App.swift
                        - buildRules: 0 elements
                        - bundleId: "io.tuist.app.tests"
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
                          ▿ iOS: Optional<String>
                            - some: "16.0"
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
                            - path: /Fixtures/ios_app_with_spm_dependencies/AppTests/AppTests.swift
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
import Foundation
import Path

public struct RunAction: Equatable, Codable {
    // MARK: - Attributes

    public let configurationName: String
    public let attachDebugger: Bool
    public let customLLDBInitFile: AbsolutePath?
    public let preActions: [ExecutionAction]
    public let postActions: [ExecutionAction]
    public let executable: TargetReference?
    public let filePath: AbsolutePath?
    public let arguments: Arguments?
    public let options: RunActionOptions
    public let diagnosticsOptions: SchemeDiagnosticsOptions
    public let metalOptions: MetalOptions
    public let expandVariableFromTarget: TargetReference?
    public let launchStyle: LaunchStyle

    // MARK: - Init

    public init(
        configurationName: String,
        attachDebugger: Bool,
        customLLDBInitFile: AbsolutePath?,
        preActions: [ExecutionAction] = [],
        postActions: [ExecutionAction] = [],
        executable: TargetReference?,
        filePath: AbsolutePath?,
        arguments: Arguments?,
        options: RunActionOptions = .init(),
        diagnosticsOptions: SchemeDiagnosticsOptions,
        metalOptions: MetalOptions,
        expandVariableFromTarget: TargetReference? = nil,
        launchStyle: LaunchStyle = .automatically
    ) {
        self.configurationName = configurationName
        self.attachDebugger = attachDebugger
        self.customLLDBInitFile = customLLDBInitFile
        self.preActions = preActions
        self.postActions = postActions
        self.executable = executable
        self.filePath = filePath
        self.arguments = arguments
        self.options = options
        self.diagnosticsOptions = diagnosticsOptions
        self.metalOptions = metalOptions
        self.expandVariableFromTarget = expandVariableFromTarget
        self.launchStyle = launchStyle
    }
}

#if DEBUG
    extension RunAction {
        public static func test(
            configurationName: String = BuildConfiguration.debug.name,
            attachDebugger: Bool = true,
            customLLDBInitFile: AbsolutePath? = nil,
            preActions: [ExecutionAction] = [],
            postActions: [ExecutionAction] = [],
            // swiftlint:disable:next force_try
            executable: TargetReference? = TargetReference(projectPath: try! AbsolutePath(validating: "/Project"), name: "App"),
            filePath: AbsolutePath? = nil,
            arguments: Arguments? = Arguments.test(),
            options: RunActionOptions = .init(),
            diagnosticsOptions: SchemeDiagnosticsOptions = XcodeGraph.SchemeDiagnosticsOptions(
                mainThreadCheckerEnabled: true,
                performanceAntipatternCheckerEnabled: true
            ),
            metalOptions: MetalOptions = XcodeGraph.MetalOptions(
                apiValidation: true
            ),
            expandVariableFromTarget: TargetReference? = nil,
            launchStyle: LaunchStyle = .automatically
        ) -> RunAction {
            RunAction(
                configurationName: configurationName,
                attachDebugger: attachDebugger,
                customLLDBInitFile: customLLDBInitFile,
                preActions: preActions,
                postActions: postActions,
                executable: executable,
                filePath: filePath,
                arguments: arguments,
                options: options,
                diagnosticsOptions: diagnosticsOptions,
                metalOptions: metalOptions,
                expandVariableFromTarget: expandVariableFromTarget,
                launchStyle: launchStyle
            )
        }
    }
#endif

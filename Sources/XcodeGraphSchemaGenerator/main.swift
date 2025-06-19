import Foundation
import XcodeGraph
import Path

@main
struct XcodeGraphSchemaGenerator {
    static func main() async throws {
        let outputPath = try AbsolutePath(validating: FileManager.default.currentDirectoryPath)
            .appending(component: "schemas")
        
        // Create schemas directory if it doesn't exist
        try FileManager.default.createDirectory(
            atPath: outputPath.pathString,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        print("Generating JSON schemas for XcodeGraph models...")
        
        // Generate schemas for main models using reflection
        let modelTypes: [(String, Any.Type)] = [
            ("Graph", Graph.self),
            ("Project", Project.self),
            ("Target", Target.self),
            ("Workspace", Workspace.self),
            ("Scheme", Scheme.self),
            ("BuildConfiguration", BuildConfiguration.self),
            ("Settings", Settings.self),
            ("Product", Product.self),
            ("Platform", Platform.self),
            ("TargetDependency", TargetDependency.self),
            ("SourceFile", SourceFile.self),
            ("Headers", Headers.self),
            ("CoreDataModel", CoreDataModel.self),
            ("TestPlan", TestPlan.self),
            ("TestAction", TestAction.self),
            ("BuildAction", BuildAction.self),
            ("RunAction", RunAction.self),
            ("ArchiveAction", ArchiveAction.self),
            ("AnalyzeAction", AnalyzeAction.self),
            ("ProfileAction", ProfileAction.self),
            ("DeploymentTargets", DeploymentTargets.self),
            ("Version", Version.self),
            ("ExecutionAction", ExecutionAction.self),
            ("Arguments", Arguments.self),
            ("EnvironmentVariable", EnvironmentVariable.self),
            ("BuildRule", BuildRule.self),
            ("CopyFilesAction", CopyFilesAction.self),
            ("TargetScript", TargetScript.self),
            ("FileElement", FileElement.self),
            ("ResourceFileElement", ResourceFileElement.self),
            ("Plist", Plist.self),
            ("Package", Package.self),
        ]
        
        for (name, type) in modelTypes {
            do {
                let schema = try generateJSONSchema(for: type, named: name)
                let jsonData = try JSONSerialization.data(
                    withJSONObject: schema,
                    options: [.prettyPrinted, .sortedKeys]
                )
                
                let filePath = outputPath.appending(component: "\(name).json")
                try jsonData.write(to: URL(fileURLWithPath: filePath.pathString))
                print("Generated schema: \(filePath.pathString)")
            } catch {
                print("Failed to generate schema for \(name): \(error)")
            }
        }
        
        print("Schema generation completed! Schemas saved to: \(outputPath.pathString)")
    }
    
    static func generateJSONSchema(for type: Any.Type, named name: String) throws -> [String: Any] {
        // Create a basic JSON Schema structure
        var schema: [String: Any] = [
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "$id": "https://github.com/tuist/XcodeGraph/schemas/\(name).json",
            "title": name,
            "description": "JSON Schema for XcodeGraph \(name) model",
            "type": "object"
        ]
        
        // Generate the schema from an example instance
        let properties = try generatePropertiesSchema(for: type, named: name)
        schema["properties"] = properties
        schema["additionalProperties"] = false
        schema["$comment"] = "Generated schema for XcodeGraph.\(name). This type conforms to Swift's Codable protocol."
        
        return schema
    }
    
    static func generatePropertiesSchema(for type: Any.Type, named name: String) throws -> [String: Any] {
        // Try to create an example instance and encode it to JSON to understand the structure
        // This approach works for types that have reasonable default values or can be instantiated
        
        // Create a sample instance for each type to understand its JSON structure
        let sampleJSON: [String: Any]
        
        switch name {
        case "Graph":
            sampleJSON = createGraphSample()
        case "Project":
            sampleJSON = createProjectSample()
        case "Target":
            sampleJSON = createTargetSample()
        case "Workspace":
            sampleJSON = createWorkspaceSample()
        case "Scheme":
            sampleJSON = createSchemeSample()
        case "BuildConfiguration":
            sampleJSON = createBuildConfigurationSample()
        case "Settings":
            sampleJSON = createSettingsSample()
        case "Product":
            sampleJSON = createProductSample()
        case "Platform":
            sampleJSON = createPlatformSample()
        case "TargetDependency":
            sampleJSON = createTargetDependencySample()
        case "SourceFile":
            sampleJSON = createSourceFileSample()
        case "Headers":
            sampleJSON = createHeadersSample()
        case "CoreDataModel":
            sampleJSON = createCoreDataModelSample()
        case "TestPlan":
            sampleJSON = createTestPlanSample()
        case "TestAction":
            sampleJSON = createTestActionSample()
        case "BuildAction":
            sampleJSON = createBuildActionSample()
        case "RunAction":
            sampleJSON = createRunActionSample()
        case "ArchiveAction":
            sampleJSON = createArchiveActionSample()
        case "AnalyzeAction":
            sampleJSON = createAnalyzeActionSample()
        case "ProfileAction":
            sampleJSON = createProfileActionSample()
        case "DeploymentTargets":
            sampleJSON = createDeploymentTargetsSample()
        case "Version":
            sampleJSON = createVersionSample()
        case "ExecutionAction":
            sampleJSON = createExecutionActionSample()
        case "Arguments":
            sampleJSON = createArgumentsSample()
        case "EnvironmentVariable":
            sampleJSON = createEnvironmentVariableSample()
        case "BuildRule":
            sampleJSON = createBuildRuleSample()
        case "CopyFilesAction":
            sampleJSON = createCopyFilesActionSample()
        case "TargetScript":
            sampleJSON = createTargetScriptSample()
        case "FileElement":
            sampleJSON = createFileElementSample()
        case "ResourceFileElement":
            sampleJSON = createResourceFileElementSample()
        case "Plist":
            sampleJSON = createPlistSample()
        case "Package":
            sampleJSON = createPackageSample()
        default:
            sampleJSON = [:]
        }
        
        return generateSchemaFromJSON(sampleJSON)
    }
    
    static func generateSchemaFromJSON(_ json: [String: Any]) -> [String: Any] {
        var properties: [String: Any] = [:]
        
        for (key, value) in json {
            properties[key] = schemaForValue(value)
        }
        
        return properties
    }
    
    static func schemaForValue(_ value: Any) -> [String: Any] {
        switch value {
        case is String:
            return ["type": "string"]
        case is Int, is Int32, is Int64:
            return ["type": "integer"]
        case is Double, is Float:
            return ["type": "number"]
        case is Bool:
            return ["type": "boolean"]
        case let array as [Any]:
            if array.isEmpty {
                return ["type": "array", "items": [:]]
            }
            return ["type": "array", "items": schemaForValue(array[0])]
        case let dict as [String: Any]:
            // Check if this dictionary represents a known model type
            if let ref = referenceForDict(dict) {
                return ["$ref": ref]
            }
            return [
                "type": "object",
                "properties": generateSchemaFromJSON(dict),
                "additionalProperties": false
            ]
        case is NSNull:
            return ["type": "null"]
        default:
            return ["type": "string", "description": "Serialized as string"]
        }
    }
    
    static func referenceForDict(_ dict: [String: Any]) -> String? {
        // Map specific property combinations to model types
        // This is a simplified approach - in a real implementation you might use more sophisticated detection
        
        // Package references
        if dict.keys.contains("type") && dict.keys.contains("url") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Package.json"
        }
        
        // TargetDependency references
        if dict.keys.contains("type") && dict.keys.contains("name") && dict.keys.contains("condition") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/TargetDependency.json"
        }
        
        // BuildConfiguration references
        if dict.keys.contains("name") && dict.keys.contains("variant") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/BuildConfiguration.json"
        }
        
        // Version references
        if dict.keys.contains("major") && dict.keys.contains("minor") && dict.keys.contains("patch") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Version.json"
        }
        
        // SourceFile references
        if dict.keys.contains("path") && dict.keys.contains("compilerFlags") && dict.keys.contains("codeGen") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/SourceFile.json"
        }
        
        // Headers references
        if dict.keys.contains("public") && dict.keys.contains("private") && dict.keys.contains("project") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Headers.json"
        }
        
        // CoreDataModel references
        if dict.keys.contains("path") && dict.keys.contains("versions") && dict.keys.contains("currentVersion") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/CoreDataModel.json"
        }
        
        // BuildRule references
        if dict.keys.contains("compilerSpec") && dict.keys.contains("fileType") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/BuildRule.json"
        }
        
        // CopyFilesAction references
        if dict.keys.contains("destination") && dict.keys.contains("subpath") && dict.keys.contains("files") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/CopyFilesAction.json"
        }
        
        // TargetScript references
        if dict.keys.contains("script") && dict.keys.contains("tool") && dict.keys.contains("order") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/TargetScript.json"
        }
        
        // FileElement references
        if dict.keys.contains("path") && dict.keys.contains("isReference") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/FileElement.json"
        }
        
        // ResourceFileElement references
        if dict.keys.contains("path") && dict.keys.contains("tags") && dict.keys.contains("inclusionCondition") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/ResourceFileElement.json"
        }
        
        // Arguments references
        if dict.keys.contains("environment") && dict.keys.contains("launchArguments") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Arguments.json"
        }
        
        // EnvironmentVariable references
        if dict.keys.contains("name") && dict.keys.contains("value") && dict.keys.contains("isEnabled") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/EnvironmentVariable.json"
        }
        
        // ExecutionAction references
        if dict.keys.contains("title") && dict.keys.contains("scriptText") && dict.keys.contains("target") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/ExecutionAction.json"
        }
        
        // Settings references
        if dict.keys.contains("base") && dict.keys.contains("configurations") && dict.keys.contains("defaultSettings") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Settings.json"
        }
        
        // Scheme references  
        if dict.keys.contains("buildAction") && dict.keys.contains("testAction") && dict.keys.contains("runAction") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Scheme.json"
        }
        
        // Target references
        if dict.keys.contains("bundleId") && dict.keys.contains("destinations") && dict.keys.contains("product") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Target.json"
        }
        
        // Project references
        if dict.keys.contains("xcodeProjPath") && dict.keys.contains("targets") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Project.json"
        }
        
        // Workspace references
        if dict.keys.contains("xcWorkspacePath") && dict.keys.contains("projects") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Workspace.json"
        }
        
        // DeploymentTargets references
        if dict.keys.contains("iOS") || dict.keys.contains("macOS") || dict.keys.contains("watchOS") || dict.keys.contains("tvOS") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/DeploymentTargets.json"
        }
        
        return nil
    }
    
    // Sample creation methods for each type
    static func createGraphSample() -> [String: Any] {
        return [
            "name": "SampleGraph",
            "path": "/path/to/graph",
            "workspace": [:],
            "projects": [:],
            "packages": [:],
            "dependencies": [:],
            "dependencyConditions": [:]
        ]
    }
    
    static func createProjectSample() -> [String: Any] {
        return [
            "path": "/path/to/project",
            "sourceRootPath": "/path/to/sources",
            "xcodeProjPath": "/path/to/project.xcodeproj",
            "name": "SampleProject",
            "organizationName": "Organization",
            "classPrefix": "SP",
            "defaultKnownRegions": ["en"],
            "developmentRegion": "en",
            "options": [:],
            "settings": ["base": [:], "configurations": [:], "defaultSettings": "recommended"],
            "targets": ["SampleTarget": ["name": "SampleTarget", "bundleId": "com.example.app", "destinations": ["iOS"], "product": "app"]],
            "packages": ["SamplePackage": ["type": "remote", "url": "https://github.com/example/package", "requirement": [:]]],
            "schemes": [["name": "SampleScheme", "buildAction": [:], "testAction": [:], "runAction": [:]]],
            "ideTemplateMacros": [:],
            "additionalFiles": [["path": "/path/to/file", "isReference": false]],
            "resourceSynthesizers": [],
            "lastKnownUpgradeCheck": "1500",
            "isExternal": false
        ]
    }
    
    static func createTargetSample() -> [String: Any] {
        return [
            "name": "SampleTarget",
            "destinations": ["iOS"],
            "product": "app",
            "bundleId": "com.example.app",
            "productName": "SampleApp",
            "deploymentTargets": ["iOS": "14.0", "macOS": "11.0"],
            "infoPlist": ["path": "/path/to/Info.plist", "content": [:]],
            "entitlements": ["path": "/path/to/entitlements.plist", "content": [:]],
            "settings": ["base": [:], "configurations": [:], "defaultSettings": "recommended"],
            "dependencies": [["type": "target", "name": "DependentTarget", "condition": [:]]],
            "sources": [["path": "/path/to/file.swift", "compilerFlags": [], "codeGen": [:]]],
            "resources": [["path": "/path/to/resource", "tags": [], "inclusionCondition": [:]]],
            "copyFiles": [["name": "Copy Files", "destination": "resources", "subpath": "", "files": []]],
            "headers": ["public": [], "private": [], "project": []],
            "coreDataModels": [["path": "/path/to/model.xcdatamodeld", "versions": [], "currentVersion": "Model"]],
            "scripts": [["name": "Script Phase", "script": "echo 'Running script'", "tool": "shell", "order": "pre", "inputPaths": [], "inputFileListPaths": [], "outputPaths": [], "outputFileListPaths": [], "showEnvVarsInLog": false, "runForInstallBuildsOnly": false, "basedOnDependencyAnalysis": false]],
            "environmentVariables": [["name": "ENV_VAR", "value": "value", "isEnabled": true]],
            "launchArguments": [],
            "additionalFiles": [["path": "/path/to/file", "isReference": false]],
            "buildRules": [["compilerSpec": "custom", "fileType": "pattern.input", "name": "Custom Rule", "filePatterns": "*.custom", "script": "echo 'Processing'", "outputFiles": [], "outputFilesCompilerFlags": [], "inputFiles": [], "dependencyFile": "", "runOncePerArchitecture": false]],
            "mergedBinaryType": "automatic",
            "mergeable": false,
            "onDemandResourcesTags": [:]
        ]
    }
    
    static func createWorkspaceSample() -> [String: Any] {
        return [
            "path": "/path/to/workspace",
            "xcWorkspacePath": "/path/to/workspace.xcworkspace",
            "name": "SampleWorkspace",
            "projects": [["path": "/path/to/project", "xcodeProjPath": "/path/to/project.xcodeproj", "targets": [:]]],
            "schemes": [["name": "SampleScheme", "buildAction": [:], "testAction": [:], "runAction": [:]]],
            "ideTemplateMacros": [:],
            "additionalFiles": [["path": "/path/to/file", "isReference": false]],
            "generationOptions": [:]
        ]
    }
    
    static func createSchemeSample() -> [String: Any] {
        return [
            "name": "SampleScheme",
            "shared": true,
            "hidden": false,
            "buildAction": [:],
            "testAction": [:],
            "runAction": [:],
            "archiveAction": [:],
            "profileAction": [:],
            "analyzeAction": [:]
        ]
    }
    
    static func createBuildConfigurationSample() -> [String: Any] {
        return [
            "name": "Debug",
            "variant": "debug"
        ]
    }
    
    static func createSettingsSample() -> [String: Any] {
        return [
            "base": [:],
            "configurations": [:],
            "defaultSettings": "recommended"
        ]
    }
    
    static func createProductSample() -> [String: Any] {
        return ["rawValue": "app"]
    }
    
    static func createPlatformSample() -> [String: Any] {
        return ["rawValue": "iOS"]
    }
    
    static func createTargetDependencySample() -> [String: Any] {
        return [
            "type": "target",
            "name": "DependentTarget",
            "condition": [:]
        ]
    }
    
    static func createSourceFileSample() -> [String: Any] {
        return [
            "path": "/path/to/file.swift",
            "compilerFlags": [],
            "codeGen": [:]
        ]
    }
    
    static func createHeadersSample() -> [String: Any] {
        return [
            "public": [],
            "private": [],
            "project": []
        ]
    }
    
    static func createCoreDataModelSample() -> [String: Any] {
        return [
            "path": "/path/to/model.xcdatamodeld",
            "versions": [],
            "currentVersion": "Model"
        ]
    }
    
    static func createTestPlanSample() -> [String: Any] {
        return [
            "path": "/path/to/testplan.xctestplan",
            "defaultOptions": [:],
            "testTargets": []
        ]
    }
    
    static func createTestActionSample() -> [String: Any] {
        return [
            "targets": [],
            "arguments": [:],
            "configurationName": "Debug",
            "coverage": false,
            "codeCoverageTargets": [],
            "preActions": [],
            "postActions": [],
            "diagnosticsOptions": [:]
        ]
    }
    
    static func createBuildActionSample() -> [String: Any] {
        return [
            "targets": [],
            "preActions": [],
            "postActions": [],
            "runPostActionsOnFailure": false
        ]
    }
    
    static func createRunActionSample() -> [String: Any] {
        return [
            "configurationName": "Debug",
            "executable": [:],
            "arguments": [:],
            "options": [:],
            "diagnosticsOptions": [:]
        ]
    }
    
    static func createArchiveActionSample() -> [String: Any] {
        return [
            "configurationName": "Release",
            "revealArchiveInOrganizer": true,
            "customArchiveName": "",
            "preActions": [],
            "postActions": []
        ]
    }
    
    static func createAnalyzeActionSample() -> [String: Any] {
        return [
            "configurationName": "Debug"
        ]
    }
    
    static func createProfileActionSample() -> [String: Any] {
        return [
            "configurationName": "Release",
            "executable": [:],
            "arguments": [:]
        ]
    }
    
    static func createDeploymentTargetsSample() -> [String: Any] {
        return [
            "iOS": "14.0",
            "macOS": "11.0",
            "watchOS": "7.0",
            "tvOS": "14.0"
        ]
    }
    
    static func createVersionSample() -> [String: Any] {
        return [
            "major": 1,
            "minor": 0,
            "patch": 0
        ]
    }
    
    static func createExecutionActionSample() -> [String: Any] {
        return [
            "title": "Script",
            "scriptText": "echo 'Hello'",
            "target": "SampleTarget",
            "shellPath": "/bin/sh",
            "showEnvVarsInLog": false
        ]
    }
    
    static func createArgumentsSample() -> [String: Any] {
        return [
            "environment": [:],
            "launchArguments": []
        ]
    }
    
    static func createEnvironmentVariableSample() -> [String: Any] {
        return [
            "name": "ENV_VAR",
            "value": "value",
            "isEnabled": true
        ]
    }
    
    static func createBuildRuleSample() -> [String: Any] {
        return [
            "compilerSpec": "custom",
            "fileType": "pattern.input",
            "name": "Custom Rule",
            "filePatterns": "*.custom",
            "script": "echo 'Processing'",
            "outputFiles": [],
            "outputFilesCompilerFlags": [],
            "inputFiles": [],
            "dependencyFile": "",
            "runOncePerArchitecture": false
        ]
    }
    
    static func createCopyFilesActionSample() -> [String: Any] {
        return [
            "name": "Copy Files",
            "destination": "resources",
            "subpath": "",
            "files": []
        ]
    }
    
    static func createTargetScriptSample() -> [String: Any] {
        return [
            "name": "Script Phase",
            "script": "echo 'Running script'",
            "tool": "shell",
            "order": "pre",
            "inputPaths": [],
            "inputFileListPaths": [],
            "outputPaths": [],
            "outputFileListPaths": [],
            "showEnvVarsInLog": false,
            "runForInstallBuildsOnly": false,
            "basedOnDependencyAnalysis": false
        ]
    }
    
    static func createFileElementSample() -> [String: Any] {
        return [
            "path": "/path/to/file",
            "isReference": false
        ]
    }
    
    static func createResourceFileElementSample() -> [String: Any] {
        return [
            "path": "/path/to/resource",
            "tags": [],
            "inclusionCondition": [:]
        ]
    }
    
    static func createPlistSample() -> [String: Any] {
        return [
            "path": "/path/to/Info.plist",
            "content": [:]
        ]
    }
    
    static func createPackageSample() -> [String: Any] {
        return [
            "type": "remote",
            "url": "https://github.com/example/package",
            "requirement": [:]
        ]
    }
}
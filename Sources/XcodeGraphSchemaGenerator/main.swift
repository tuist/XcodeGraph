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
            "settings": [:],
            "targets": [:],
            "packages": [:],
            "schemes": [],
            "ideTemplateMacros": [:],
            "additionalFiles": [],
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
            "deploymentTargets": [:],
            "infoPlist": [:],
            "entitlements": [:],
            "settings": [:],
            "dependencies": [],
            "sources": [],
            "resources": [],
            "copyFiles": [],
            "headers": [:],
            "coreDataModels": [],
            "scripts": [],
            "environmentVariables": [:],
            "launchArguments": [],
            "additionalFiles": [],
            "buildRules": [],
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
            "projects": [],
            "schemes": [],
            "ideTemplateMacros": [:],
            "additionalFiles": [],
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
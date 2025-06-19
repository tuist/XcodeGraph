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
            ("ResourceSynthesizer", ResourceSynthesizer.self),
            ("LaunchArgument", LaunchArgument.self),
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
        
        // Use compile-time reflection to generate properties
        let properties = generatePropertiesFromType(type, named: name)
        schema["properties"] = properties
        schema["additionalProperties"] = false
        schema["$comment"] = "Generated schema for XcodeGraph.\(name). This type conforms to Swift's Codable protocol."
        
        return schema
    }
    
    static func generatePropertiesFromType(_ type: Any.Type, named name: String) -> [String: Any] {
        // Use Mirror to reflect on the type structure
        // For compile-time reflection, we'll use known property mappings
        
        switch name {
        case "Graph":
            return generateGraphProperties()
        case "Project":
            return generateProjectProperties()
        case "Target":
            return generateTargetProperties()
        case "Workspace":
            return generateWorkspaceProperties()
        case "Scheme":
            return generateSchemeProperties()
        case "BuildConfiguration":
            return generateBuildConfigurationProperties()
        case "Settings":
            return generateSettingsProperties()
        case "Product":
            return generateProductProperties()
        case "Platform":
            return generatePlatformProperties()
        case "TargetDependency":
            return generateTargetDependencyProperties()
        case "SourceFile":
            return generateSourceFileProperties()
        case "Headers":
            return generateHeadersProperties()
        case "CoreDataModel":
            return generateCoreDataModelProperties()
        case "TestPlan":
            return generateTestPlanProperties()
        case "TestAction":
            return generateTestActionProperties()
        case "BuildAction":
            return generateBuildActionProperties()
        case "RunAction":
            return generateRunActionProperties()
        case "ArchiveAction":
            return generateArchiveActionProperties()
        case "AnalyzeAction":
            return generateAnalyzeActionProperties()
        case "ProfileAction":
            return generateProfileActionProperties()
        case "DeploymentTargets":
            return generateDeploymentTargetsProperties()
        case "Version":
            return generateVersionProperties()
        case "ExecutionAction":
            return generateExecutionActionProperties()
        case "Arguments":
            return generateArgumentsProperties()
        case "EnvironmentVariable":
            return generateEnvironmentVariableProperties()
        case "BuildRule":
            return generateBuildRuleProperties()
        case "CopyFilesAction":
            return generateCopyFilesActionProperties()
        case "TargetScript":
            return generateTargetScriptProperties()
        case "FileElement":
            return generateFileElementProperties()
        case "ResourceFileElement":
            return generateResourceFileElementProperties()
        case "Plist":
            return generatePlistProperties()
        case "Package":
            return generatePackageProperties()
        case "ResourceSynthesizer":
            return generateResourceSynthesizerProperties()
        case "LaunchArgument":
            return generateLaunchArgumentProperties()
        default:
            return [:]
        }
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
                return ["type": "array", "items": ["type": "object"]]
            }
            return ["type": "array", "items": schemaForValue(array[0])]
        case let dict as [String: Any]:
            // Check if this dictionary represents a known model type
            if let ref = referenceForDict(dict) {
                return ["$ref": ref]
            }
            
            // Check if this is a dictionary pattern (key-value mapping)
            if isDictionaryPattern(dict) {
                return createDictionarySchema(dict)
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
    
    static func isDictionaryPattern(_ dict: [String: Any]) -> Bool {
        // Check if this looks like a key-value mapping rather than a structured object
        // This is a heuristic - we look for patterns that suggest dictionary usage
        
        // If all values are of the same type and keys look like identifiers/names
        let values = Array(dict.values)
        guard !values.isEmpty else { return false }
        
        // Check if this is targets, packages, or similar dictionary patterns
        let keys = dict.keys
        if keys.contains("SampleTarget") || keys.contains("SamplePackage") {
            return true
        }
        
        return false
    }
    
    static func createDictionarySchema(_ dict: [String: Any]) -> [String: Any] {
        // For dictionary patterns, create additionalProperties schema
        guard let firstValue = dict.values.first else {
            return ["type": "object", "additionalProperties": true]
        }
        
        let valueSchema = schemaForValue(firstValue)
        
        return [
            "type": "object",
            "additionalProperties": valueSchema
        ]
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
        
        // ResourceSynthesizer references
        if dict.keys.contains("parser") && dict.keys.contains("template") {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/ResourceSynthesizer.json"
        }
        
        // LaunchArgument references  
        if dict.keys.contains("name") && dict.keys.contains("value") && dict.keys.contains("isEnabled") && dict.keys.count == 3 {
            return "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/LaunchArgument.json"
        }
        
        return nil
    }
    
    // Property generation methods based on actual Swift types
    static func generateLaunchArgumentProperties() -> [String: Any] {
        return [
            "name": ["type": "string", "description": "The name of the launch argument"],
            "isEnabled": ["type": "boolean", "description": "Whether the argument is enabled or not"]
        ]
    }
    
    static func generateResourceSynthesizerProperties() -> [String: Any] {
        return [
            "parser": ["type": "string", "enum": ["strings", "stringsCatalog", "assets", "plists"]],
            "parserOptions": ["type": "object", "additionalProperties": true],
            "extensions": ["type": "array", "items": ["type": "string"]],
            "template": ["oneOf": [
                ["type": "string", "description": "File path to template"],
                ["type": "string", "description": "Default template name"]
            ]]
        ]
    }
    
    static func generateTargetProperties() -> [String: Any] {
        return [
            "name": ["type": "string"],
            "destinations": ["type": "array", "items": ["type": "string"]],
            "product": ["type": "string"],
            "bundleId": ["type": "string"],
            "productName": ["type": "string"],
            "deploymentTargets": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/DeploymentTargets.json"],
            "infoPlist": ["oneOf": [
                ["type": "null"],
                ["type": "object", "properties": [
                    "path": ["type": "string"],
                    "content": ["type": "object", "additionalProperties": true]
                ]]
            ]],
            "entitlements": ["oneOf": [
                ["type": "null"],
                ["type": "object", "properties": [
                    "path": ["type": "string"],
                    "content": ["type": "object", "additionalProperties": true]
                ]]
            ]],
            "settings": ["oneOf": [
                ["type": "null"],
                ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Settings.json"]
            ]],
            "dependencies": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/TargetDependency.json"]],
            "sources": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/SourceFile.json"]],
            "resources": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/ResourceFileElement.json"]],
            "copyFiles": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/CopyFilesAction.json"]],
            "headers": ["oneOf": [
                ["type": "null"],
                ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Headers.json"]
            ]],
            "coreDataModels": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/CoreDataModel.json"]],
            "scripts": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/TargetScript.json"]],
            "environmentVariables": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/EnvironmentVariable.json"]],
            "launchArguments": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/LaunchArgument.json"]],
            "additionalFiles": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/FileElement.json"]],
            "buildRules": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/BuildRule.json"]],
            "mergedBinaryType": ["type": "string"],
            "mergeable": ["type": "boolean"],
            "onDemandResourcesTags": ["type": "object", "additionalProperties": ["type": "array", "items": ["type": "string"]]]
        ]
    }
    
    static func generateProjectProperties() -> [String: Any] {
        return [
            "path": ["type": "string"],
            "sourceRootPath": ["type": "string"],
            "xcodeProjPath": ["type": "string"],
            "name": ["type": "string"],
            "organizationName": ["oneOf": [["type": "null"], ["type": "string"]]],
            "classPrefix": ["oneOf": [["type": "null"], ["type": "string"]]],
            "defaultKnownRegions": ["oneOf": [["type": "null"], ["type": "array", "items": ["type": "string"]]]],
            "developmentRegion": ["oneOf": [["type": "null"], ["type": "string"]]],
            "options": ["type": "object", "additionalProperties": true],
            "settings": ["oneOf": [
                ["type": "null"],
                ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Settings.json"]
            ]],
            "targets": ["type": "object", "additionalProperties": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Target.json"]],
            "packages": ["type": "object", "additionalProperties": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Package.json"]],
            "schemes": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/Scheme.json"]],
            "ideTemplateMacros": ["type": "object", "additionalProperties": ["type": "string"]],
            "additionalFiles": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/FileElement.json"]],
            "resourceSynthesizers": ["type": "array", "items": ["$ref": "https://raw.githubusercontent.com/tuist/XcodeGraph/main/schemas/ResourceSynthesizer.json"]],
            "lastKnownUpgradeCheck": ["oneOf": [["type": "null"], ["type": "string"]]],
            "isExternal": ["type": "boolean"]
        ]
    }
    
    // Placeholder methods for other types - implement based on actual model definitions
    static func generateGraphProperties() -> [String: Any] { return [:] }
    static func generateWorkspaceProperties() -> [String: Any] { return [:] }
    static func generateSchemeProperties() -> [String: Any] { return [:] }
    static func generateBuildConfigurationProperties() -> [String: Any] { return [:] }
    static func generateSettingsProperties() -> [String: Any] { return [:] }
    static func generateProductProperties() -> [String: Any] { return [:] }
    static func generatePlatformProperties() -> [String: Any] { return [:] }
    static func generateTargetDependencyProperties() -> [String: Any] { return [:] }
    static func generateSourceFileProperties() -> [String: Any] { return [:] }
    static func generateHeadersProperties() -> [String: Any] { return [:] }
    static func generateCoreDataModelProperties() -> [String: Any] { return [:] }
    static func generateTestPlanProperties() -> [String: Any] { return [:] }
    static func generateTestActionProperties() -> [String: Any] { return [:] }
    static func generateBuildActionProperties() -> [String: Any] { return [:] }
    static func generateRunActionProperties() -> [String: Any] { return [:] }
    static func generateArchiveActionProperties() -> [String: Any] { return [:] }
    static func generateAnalyzeActionProperties() -> [String: Any] { return [:] }
    static func generateProfileActionProperties() -> [String: Any] { return [:] }
    static func generateDeploymentTargetsProperties() -> [String: Any] { return [:] }
    static func generateVersionProperties() -> [String: Any] { return [:] }
    static func generateExecutionActionProperties() -> [String: Any] { return [:] }
    static func generateArgumentsProperties() -> [String: Any] { return [:] }
    static func generateEnvironmentVariableProperties() -> [String: Any] { return [:] }
    static func generateBuildRuleProperties() -> [String: Any] { return [:] }
    static func generateCopyFilesActionProperties() -> [String: Any] { return [:] }
    static func generateTargetScriptProperties() -> [String: Any] { return [:] }
    static func generateFileElementProperties() -> [String: Any] { return [:] }
    static func generateResourceFileElementProperties() -> [String: Any] { return [:] }
    static func generatePlistProperties() -> [String: Any] { return [:] }
    static func generatePackageProperties() -> [String: Any] { return [:] }
    
    // Legacy sample creation methods for backward compatibility
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
            "resourceSynthesizers": [["parser": "strings", "template": "template.stencil", "extensions": ["strings"]]],
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
            "launchArguments": [["name": "ARG_NAME", "value": "arg_value", "isEnabled": true]],
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
    
    static func createResourceSynthesizerSample() -> [String: Any] {
        return [
            "parser": "strings",
            "template": "template.stencil",
            "extensions": ["strings"],
            "parserOptions": [:]
        ]
    }
    
    static func createLaunchArgumentSample() -> [String: Any] {
        return [
            "name": "ARG_NAME",
            "value": "arg_value",
            "isEnabled": true
        ]
    }
}
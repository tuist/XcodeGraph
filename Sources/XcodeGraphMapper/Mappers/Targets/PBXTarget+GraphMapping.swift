import Foundation
import Path
import XcodeGraph
import XcodeProj

extension PBXTarget {
    /// Attempts to retrieve the bundle identifier from the target's debug build settings, or throws an error if missing.
    func bundleIdentifier() throws -> String {
        if let bundleId = debugBuildSettings.string(for: .productBundleIdentifier) {
            return bundleId
        }
        throw PBXTargetMappingError.missingBundleIdentifier(targetName: name)
    }

    /// Returns an array of all `PBXCopyFilesBuildPhase` instances for this target.
    func copyFilesBuildPhases() -> [PBXCopyFilesBuildPhase] {
        buildPhases.compactMap { $0 as? PBXCopyFilesBuildPhase }
    }

    func launchArguments() throws -> [LaunchArgument] {
        guard let buildConfigList = buildConfigurationList else { return [] }
        var launchArguments: [LaunchArgument] = []
        for buildConfig in buildConfigList.buildConfigurations {
            if let args = buildConfig.buildSettings.stringArray(for: .launchArguments) {
                launchArguments.append(contentsOf: args.map { LaunchArgument(name: $0, isEnabled: true) })
            }
        }
        return launchArguments.uniqued()
    }

    func prune() throws -> Bool {
        debugBuildSettings.bool(for: .prune) ?? false
    }

    func mergedBinaryType() throws -> MergedBinaryType {
        let mergedBinaryTypeString = debugBuildSettings.string(for: .mergedBinaryType)
        return mergedBinaryTypeString == "automatic" ? .automatic : .disabled
    }

    func mergeable() throws -> Bool {
        debugBuildSettings.bool(for: .mergeable) ?? false
    }

    func onDemandResourcesTags() throws -> OnDemandResourcesTags? {
        // Currently returns nil, could be extended if needed
        return nil
    }

    func metadata() throws -> TargetMetadata {
        var tags: Set<String> = []
        for buildConfig in buildConfigurationList?.buildConfigurations ?? [] {
            if let tagsString = buildConfig.buildSettings.string(for: .tags) {
                let extractedTags = tagsString
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                tags.formUnion(extractedTags)
            }
        }
        return .metadata(tags: tags)
    }
}

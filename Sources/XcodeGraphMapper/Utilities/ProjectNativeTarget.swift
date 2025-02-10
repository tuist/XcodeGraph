import XcodeProj

/// Model representing a `PBXNativeTarget` in a give `XcodeProj`
struct ProjectNativeTarget {
    let nativeTarget: PBXNativeTarget
    let project: XcodeProj
}

import XcodeProj

extension PBXProject {
    /// Retrieves the value of a specific project attribute.
    ///
    /// - Parameter attr: The attribute key to look up.
    /// - Returns: The value of the attribute if it exists, or `nil` if not found.
    func attribute(for attr: ProjectAttribute) -> String? {
        attributes[attr.rawValue] as? String
    }
}

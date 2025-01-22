 import XcodeGraph
 @testable import MetadataProviders
 import Testing

 @Suite
 struct SystemFrameworkMetadataProviderTests {
    var subject: SystemFrameworkMetadataProvider

    /// Initializes the test suite, setting up the required `SystemFrameworkMetadataProvider` instance.
    init() {
        subject = SystemFrameworkMetadataProvider()
    }

    @Test
    func loadMetadataFramework() throws {
        // Given
        let sdkName = "UIKit.framework"

        // When
        let metadata = try subject.loadMetadata(sdkName: sdkName, status: .required, platform: .iOS, source: .system)

        // Then
        #expect(
            metadata == SystemFrameworkMetadata(
                name: sdkName,
                path: "/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/UIKit.framework",
                status: .required,
                source: .system
            ),
            "Metadata does not match expected value"
        )
    }

    @Test
    func loadMetadataLibrary() throws {
        // Given
        let sdkName = "libc++.tbd"

        // When
        let metadata = try subject.loadMetadata(sdkName: sdkName, status: .required, platform: .iOS, source: .system)

        // Then
        #expect(
            metadata == SystemFrameworkMetadata(
                name: sdkName,
                path: "/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/libc++.tbd",
                status: .required,
                source: .system
            ),
            "Metadata does not match expected value"
        )
    }

    @Test
    func loadMetadataSwiftLibrary() throws {
        // Given
        let sdkName = "libswiftObservation.tbd"

        // When
        let metadata = try subject.loadMetadata(sdkName: sdkName, status: .required, platform: .iOS, source: .system)

        // Then
        #expect(
            metadata == SystemFrameworkMetadata(
                name: sdkName,
                path: "/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib/swift/libswiftObservation.tbd",
                status: .required,
                source: .system
            ),
            "Metadata does not match expected value"
        )
    }

    @Test
    func loadMetadataUnsupportedType() throws {
        // Given
        let sdkName = "UIKit.xcframework"

        // When / Then
        #expect(
            throws: SystemFrameworkMetadataProviderError.unsupportedSDK(name: sdkName)
        ) {
            try subject.loadMetadata(sdkName: sdkName, status: .required, platform: .iOS, source: .system)
        }
    }

    @Test
    func loadMetadataDeveloperSourceSupportedPlatform() throws {
        // Given
        let sdkName = "XCTest.framework"
        let source = SDKSource.developer
        let platform = Platform.iOS

        // When
        let metadata = try subject.loadMetadata(sdkName: sdkName, status: .required, platform: platform, source: source)

        // Then
        #expect(
            metadata == SystemFrameworkMetadata(
                name: sdkName,
                path: "/Platforms/iPhoneOS.platform/Developer/Library/Frameworks/XCTest.framework",
                status: .required,
                source: .developer
            ),
            "Metadata does not match expected value"
        )
    }
 }

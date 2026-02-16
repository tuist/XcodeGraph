import Foundation
import XCTest
@testable import XcodeGraph

final class ResourceSynthesizerTests: XCTestCase {
    func test_codable() {
        // Given
        let subject = ResourceSynthesizer(
            parser: .coreData,
            parserOptions: ["key": "value"],
            extensions: [
                "extension1",
                "extension2",
            ],
            template: .defaultTemplate("template"),
            templateParameters: [
                "someInt": 1,
                "someDouble": 1.2,
                "someString": "string",
                "someBool": true,
                "someArrayOfString": ["a", "b", "c"],
                "someArrayOfInt": [1, 2, 3],
                "someDictionary": [
                    "someInt": 1,
                    "someDouble": 1.2,
                    "someString": "string",
                    "someBool": true,
                    "someArrayOfString": ["a", "b", "c"],
                    "someArrayOfInt": [1, 2, 3],
                ],
            ]
        )

        // Then
        XCTAssertCodable(subject)
    }
}

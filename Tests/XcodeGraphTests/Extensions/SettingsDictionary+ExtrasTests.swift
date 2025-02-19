import Foundation
import Testing

@testable import XcodeGraph

struct SettingsDictionaryExtrasTest {
    @Test
    func test_combine_doesNotIncludeDuplicates() {
        // Given
        let settings: [String: SettingValue] = [
            "A": .array(["first value", "second value"]),
        ]

        // When
        let got = settings.combine(
            with: [
                "A": .array(
                    [
                        "first value", "third value",
                    ]
                ),
            ]
        )
        .mapValues { value -> SettingValue in
            switch value {
            case let .array(values): return .array(values.sorted())
            default: return value
            }
        }

        // Then
        #expect(
            got == [
                "A": .array(
                    [
                        "first value", "second value", "third value",
                    ]
                ),
            ]
        )
    }

    @Test
    func testOverlay_addsPlatformSpecifierWhenSettingsDiffer() {
        // Given
        var settings: [String: SettingValue] = [
            "A": "a value",
            "B": "b value",
        ]

        // When
        settings.overlay(with: [
            "A": "overlayed value",
            "B": "b value",
            "C": "c value",
        ], for: .macOS)

        // Then
        #expect(
            settings == [
                "A[sdk=macosx*]": "overlayed value",
                "A": "a value",
                "B": "b value",
                "C[sdk=macosx*]": "c value",
            ]
        )
    }
}

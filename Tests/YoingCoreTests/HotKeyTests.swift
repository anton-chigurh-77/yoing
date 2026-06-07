@testable import YoingCore
import CoreGraphics
import XCTest

final class HotKeyTests: XCTestCase {
    func testDefaultDictationHotKeyIsFunctionOnly() {
        XCTAssertEqual(HotKey.defaultDictation, .functionOnly)
        XCTAssertEqual(HotKey.defaultDictation.displayName, "Fn / Globe")
        XCTAssertTrue(HotKey.defaultDictation.isValid)
    }

    func testFunctionOnlyCodableRoundTrip() throws {
        let data = try JSONEncoder().encode(HotKey.defaultDictation)
        let decoded = try JSONDecoder().decode(HotKey.self, from: data)

        XCTAssertEqual(decoded, .functionOnly)
    }

    func testKeyCombinationCodableRoundTripAndDisplayName() throws {
        let hotKey = HotKey(keyCode: 0x28, modifiers: [.maskCommand, .maskShift])
        let data = try JSONEncoder().encode(hotKey)
        let decoded = try JSONDecoder().decode(HotKey.self, from: data)

        XCTAssertEqual(decoded, hotKey)
        XCTAssertEqual(decoded.displayName, "Command Shift K")
    }

    func testNoModifierKeyCombinationIsValid() {
        let hotKey = HotKey(keyCode: 0x00, modifiers: [])

        XCTAssertTrue(hotKey.isValid)
        XCTAssertEqual(hotKey.displayName, "A")
        XCTAssertTrue(hotKey.matchesKeyDown(keyCode: 0x00, flags: []))
    }

    func testModifierOnlyKeyCombinationIsInvalid() {
        let hotKey = HotKey(keyCode: 0x37, modifiers: [])

        XCTAssertFalse(hotKey.isValid)
    }

    func testKeyCombinationRequiresExactModifiers() {
        let hotKey = HotKey(keyCode: 0x28, modifiers: [.maskCommand, .maskShift])

        XCTAssertTrue(
            hotKey.matchesKeyDown(
                keyCode: 0x28,
                flags: [.maskCommand, .maskShift]
            )
        )
        XCTAssertFalse(
            hotKey.matchesKeyDown(
                keyCode: 0x28,
                flags: [.maskCommand]
            )
        )
        XCTAssertFalse(
            hotKey.matchesKeyDown(
                keyCode: 0x28,
                flags: [.maskCommand, .maskShift, .maskAlternate]
            )
        )
        XCTAssertTrue(hotKey.matchesKeyUp(keyCode: 0x28))
        XCTAssertFalse(hotKey.matchesKeyUp(keyCode: 0x00))
    }

    func testFunctionOnlyMatchesFlagsChangedPressAndRelease() {
        let hotKey = HotKey.functionOnly

        XCTAssertTrue(
            hotKey.matchesFunctionPress(
                keyCode: HotKey.functionKeyCode,
                previousFlags: [],
                currentFlags: [.maskSecondaryFn]
            )
        )
        XCTAssertFalse(
            hotKey.matchesFunctionPress(
                keyCode: HotKey.functionKeyCode,
                previousFlags: [.maskSecondaryFn],
                currentFlags: [.maskSecondaryFn]
            )
        )
        XCTAssertTrue(
            hotKey.matchesFunctionRelease(
                keyCode: HotKey.functionKeyCode,
                previousFlags: [.maskSecondaryFn],
                currentFlags: []
            )
        )
        XCTAssertFalse(
            hotKey.matchesFunctionRelease(
                keyCode: HotKey.functionKeyCode,
                previousFlags: [],
                currentFlags: []
            )
        )
    }

    func testRegularHotKeyDoesNotMatchFunctionOnlyEvents() {
        let hotKey = HotKey(keyCode: 0x31, modifiers: .maskAlternate)

        XCTAssertFalse(
            hotKey.matchesFunctionPress(
                keyCode: HotKey.functionKeyCode,
                previousFlags: [],
                currentFlags: [.maskSecondaryFn]
            )
        )
    }
}

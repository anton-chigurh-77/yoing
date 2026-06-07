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

    func testNoModifierKeyCombinationIsInvalid() {
        let hotKey = HotKey(keyCode: 0x00, modifiers: [])

        XCTAssertFalse(hotKey.isValid)
        XCTAssertEqual(hotKey.displayName, "A")
        XCTAssertFalse(hotKey.matchesKeyDown(keyCode: 0x00, flags: []))
    }

    func testShiftOnlyKeyCombinationIsInvalid() {
        let hotKey = HotKey(keyCode: 0x00, modifiers: .maskShift)

        XCTAssertFalse(hotKey.isValid)
    }

    func testFunctionModifierKeyCombinationIsInvalid() {
        let hotKey = HotKey(keyCode: 0x28, modifiers: [.maskSecondaryFn])

        XCTAssertFalse(hotKey.isValid)
        XCTAssertFalse(hotKey.matchesKeyDown(keyCode: 0x28, flags: [.maskSecondaryFn]))
    }

    func testModifierOnlyKeyCombinationIsInvalid() {
        let hotKey = HotKey(keyCode: 0x37, modifiers: [])

        XCTAssertFalse(hotKey.isValid)
    }

    func testKeyCombinationRequiresSemanticModifiers() {
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
        XCTAssertTrue(
            hotKey.matchesKeyDown(
                keyCode: 0x28,
                flags: [.maskCommand, .maskShift, .maskAlphaShift]
            )
        )
        XCTAssertTrue(hotKey.matchesKeyUp(keyCode: 0x28))
        XCTAssertFalse(hotKey.matchesKeyUp(keyCode: 0x00))
    }

    func testNonReservedKeyCombinationsRemainValid() {
        XCTAssertTrue(HotKey(keyCode: 0x31, modifiers: .maskAlternate).isValid)
        XCTAssertTrue(HotKey(keyCode: 0x28, modifiers: .maskControl).isValid)
        XCTAssertTrue(HotKey(keyCode: 0x28, modifiers: [.maskCommand, .maskShift]).isValid)
    }

    func testCommandReservedKeyCombinationsAreInvalid() {
        let reservedKeyCodes: [CGKeyCode] = [
            0x0C, // Q
            0x30, // Tab
            0x31, // Space
            0x0D, // W
            0x01, // S
            0x04, // H
            0x2E, // M
            0x2F, // .
            0x35  // Escape
        ]

        for keyCode in reservedKeyCodes {
            XCTAssertFalse(
                HotKey(keyCode: keyCode, modifiers: .maskCommand).isValid,
                "Command-reserved key code \(keyCode) should be invalid"
            )
        }

        XCTAssertFalse(HotKey(keyCode: 0x35, modifiers: [.maskCommand, .maskAlternate]).isValid)
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

@testable import YoingCore
import CoreGraphics
import Foundation
import XCTest

final class UserDefaultsHotKeyStoreTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: UserDefaultsHotKeyStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        suiteName = "YoingCoreTests.\(UUID().uuidString)"
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        store = UserDefaultsHotKeyStore(userDefaults: userDefaults)
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: suiteName)
        store = nil
        userDefaults = nil
        suiteName = nil

        try super.tearDownWithError()
    }

    func testLoadFallsBackToDefaultWhenUnset() {
        XCTAssertEqual(store.loadDictationHotKey(), .defaultDictation)
    }

    func testSaveAndLoadKeyCombination() throws {
        let hotKey = HotKey(keyCode: 0x28, modifiers: [.maskCommand, .maskAlternate])

        try store.saveDictationHotKey(hotKey)

        XCTAssertEqual(store.loadDictationHotKey(), hotKey)
    }

    func testResetRemovesOverrideAndFallsBackToDefault() throws {
        try store.saveDictationHotKey(HotKey(keyCode: 0x31, modifiers: .maskAlternate))

        store.resetDictationHotKey()

        XCTAssertEqual(store.loadDictationHotKey(), .defaultDictation)
    }

    func testInvalidStoredDataFallsBackToDefault() {
        userDefaults.set(Data("not-json".utf8), forKey: UserDefaultsHotKeyStore.defaultKey)

        XCTAssertEqual(store.loadDictationHotKey(), .defaultDictation)
    }

    func testInvalidStoredHotKeyFallsBackToDefault() throws {
        let invalidHotKey = HotKey(keyCode: 0x28, modifiers: .maskSecondaryFn)
        let data = try JSONEncoder().encode(invalidHotKey)
        userDefaults.set(data, forKey: UserDefaultsHotKeyStore.defaultKey)

        XCTAssertEqual(store.loadDictationHotKey(), .defaultDictation)
    }

    func testRejectsInvalidHotKey() {
        let invalidHotKey = HotKey(keyCode: 0x37, modifiers: [])

        XCTAssertThrowsError(try store.saveDictationHotKey(invalidHotKey))
    }
}

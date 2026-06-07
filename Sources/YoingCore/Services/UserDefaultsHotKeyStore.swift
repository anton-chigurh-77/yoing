import Foundation

public enum HotKeyStoreError: LocalizedError {
    case invalidHotKey

    public var errorDescription: String? {
        switch self {
        case .invalidHotKey:
            return "The selected hotkey is not supported."
        }
    }
}

public protocol HotKeyStoring {
    func loadDictationHotKey() -> HotKey
    func saveDictationHotKey(_ hotKey: HotKey) throws
    func resetDictationHotKey()
}

public final class UserDefaultsHotKeyStore: HotKeyStoring {
    public static let defaultKey = "dictationHotKey.v1"

    private let userDefaults: UserDefaults
    private let key: String
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(
        userDefaults: UserDefaults = .standard,
        key: String = UserDefaultsHotKeyStore.defaultKey
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func loadDictationHotKey() -> HotKey {
        guard
            let data = userDefaults.data(forKey: key),
            let hotKey = try? decoder.decode(HotKey.self, from: data),
            hotKey.isValid
        else {
            return .defaultDictation
        }

        return hotKey
    }

    public func saveDictationHotKey(_ hotKey: HotKey) throws {
        guard hotKey.isValid else {
            throw HotKeyStoreError.invalidHotKey
        }

        let data = try encoder.encode(hotKey)
        userDefaults.set(data, forKey: key)
    }

    public func resetDictationHotKey() {
        userDefaults.removeObject(forKey: key)
    }
}

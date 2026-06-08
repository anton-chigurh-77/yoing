import Foundation

public struct DictationUsageEvent: Equatable {
    public var date: Date
    public var wordCount: Int
    public var characterCount: Int
    public var dictatedSeconds: TimeInterval
    public var provider: String

    public init(
        date: Date = Date(),
        wordCount: Int,
        characterCount: Int,
        dictatedSeconds: TimeInterval,
        provider: String
    ) {
        self.date = date
        self.wordCount = max(0, wordCount)
        self.characterCount = max(0, characterCount)
        self.dictatedSeconds = max(0, dictatedSeconds)
        self.provider = provider.isEmpty ? "Unknown" : provider
    }

    public init(transcript: String, dictatedSeconds: TimeInterval, provider: String, date: Date = Date()) {
        self.init(
            date: date,
            wordCount: UsageWordCounter.countWords(in: transcript),
            characterCount: transcript.count,
            dictatedSeconds: dictatedSeconds,
            provider: provider
        )
    }
}

public enum UsageWordCounter {
    public static func countWords(in text: String) -> Int {
        var count = 0
        text.enumerateSubstrings(
            in: text.startIndex..<text.endIndex,
            options: [.byWords, .localized]
        ) { substring, _, _, _ in
            if substring != nil {
                count += 1
            }
        }
        return count
    }
}

public struct DailyUsageStats: Codable, Equatable, Identifiable {
    public var day: Date
    public var wordCount: Int
    public var characterCount: Int
    public var sessionCount: Int
    public var dictatedSeconds: TimeInterval
    public var providerCounts: [String: Int]

    public var id: Date {
        day
    }

    public init(
        day: Date,
        wordCount: Int = 0,
        characterCount: Int = 0,
        sessionCount: Int = 0,
        dictatedSeconds: TimeInterval = 0,
        providerCounts: [String: Int] = [:]
    ) {
        self.day = day
        self.wordCount = max(0, wordCount)
        self.characterCount = max(0, characterCount)
        self.sessionCount = max(0, sessionCount)
        self.dictatedSeconds = max(0, dictatedSeconds)
        self.providerCounts = providerCounts
    }

    public var isEmpty: Bool {
        wordCount == 0 && characterCount == 0 && sessionCount == 0 && dictatedSeconds == 0
    }

    public var wordsPerMinute: Int? {
        guard wordCount > 0, dictatedSeconds > 0 else {
            return nil
        }

        return Int((Double(wordCount) / (dictatedSeconds / 60)).rounded())
    }

    public mutating func add(_ event: DictationUsageEvent) {
        wordCount += event.wordCount
        characterCount += event.characterCount
        sessionCount += 1
        dictatedSeconds += event.dictatedSeconds
        providerCounts[event.provider, default: 0] += 1
    }

    public mutating func merge(_ other: DailyUsageStats) {
        wordCount += other.wordCount
        characterCount += other.characterCount
        sessionCount += other.sessionCount
        dictatedSeconds += other.dictatedSeconds

        for (provider, count) in other.providerCounts {
            providerCounts[provider, default: 0] += count
        }
    }
}

public struct UsageStatsSnapshot: Equatable {
    public var days: [DailyUsageStats]

    public init(days: [DailyUsageStats]) {
        self.days = days.sorted { $0.day < $1.day }
    }

    public var today: DailyUsageStats {
        days.last ?? DailyUsageStats(day: Date())
    }

    public var totalWords: Int {
        days.reduce(0) { $0 + $1.wordCount }
    }

    public var totalSessions: Int {
        days.reduce(0) { $0 + $1.sessionCount }
    }

    public var totalDictatedSeconds: TimeInterval {
        days.reduce(0) { $0 + $1.dictatedSeconds }
    }

    public var maxDailyWords: Int {
        days.map(\.wordCount).max() ?? 0
    }
}

public protocol UsageStatsStoring {
    func record(_ event: DictationUsageEvent) throws
    func snapshot(dayCount: Int, now: Date) -> UsageStatsSnapshot
}

public extension UsageStatsStoring {
    func snapshot() -> UsageStatsSnapshot {
        snapshot(dayCount: 182, now: Date())
    }
}

public final class UserDefaultsUsageStatsStore: UsageStatsStoring {
    public static let defaultStorageKey = "yoing.usageStats.v1"

    private let defaults: UserDefaults
    private let storageKey: String
    private let calendar: Calendar
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        defaults: UserDefaults = .standard,
        storageKey: String = UserDefaultsUsageStatsStore.defaultStorageKey,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.calendar = calendar
    }

    public func record(_ event: DictationUsageEvent) throws {
        let day = calendar.startOfDay(for: event.date)
        var statsByDay = loadStatsByDay()
        var stats = statsByDay[day] ?? DailyUsageStats(day: day)
        stats.add(event)
        statsByDay[day] = stats

        try save(Array(statsByDay.values))
    }

    public func snapshot(dayCount: Int = 182, now: Date = Date()) -> UsageStatsSnapshot {
        let normalizedDayCount = max(1, dayCount)
        let endDay = calendar.startOfDay(for: now)
        let startDay = calendar.date(byAdding: .day, value: -(normalizedDayCount - 1), to: endDay) ?? endDay
        let statsByDay = loadStatsByDay()

        let days = (0..<normalizedDayCount).compactMap { offset -> DailyUsageStats? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDay) else {
                return nil
            }

            return statsByDay[day] ?? DailyUsageStats(day: day)
        }

        return UsageStatsSnapshot(days: days)
    }

    private func loadStatsByDay() -> [Date: DailyUsageStats] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? decoder.decode([DailyUsageStats].self, from: data) else {
            return [:]
        }

        return decoded.reduce(into: [Date: DailyUsageStats]()) { partialResult, stats in
            let day = calendar.startOfDay(for: stats.day)
            var normalized = stats
            normalized.day = day

            if var existing = partialResult[day] {
                existing.merge(normalized)
                partialResult[day] = existing
            } else {
                partialResult[day] = normalized
            }
        }
    }

    private func save(_ stats: [DailyUsageStats]) throws {
        let nonEmptyStats = stats
            .filter { !$0.isEmpty }
            .sorted { $0.day < $1.day }
        let data = try encoder.encode(nonEmptyStats)
        defaults.set(data, forKey: storageKey)
    }
}

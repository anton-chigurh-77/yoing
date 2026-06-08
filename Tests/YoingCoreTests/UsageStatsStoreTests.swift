import Foundation
import XCTest
@testable import YoingCore

final class UsageStatsStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar!
    private var store: UserDefaultsUsageStatsStore!

    override func setUpWithError() throws {
        suiteName = "YoingCoreTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        self.calendar = calendar
        store = UserDefaultsUsageStatsStore(defaults: defaults, calendar: calendar)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        store = nil
        calendar = nil
        suiteName = nil
    }

    func testWordCounterCountsNaturalWords() {
        XCTAssertEqual(UsageWordCounter.countWords(in: "Hello, world. This is Yoing."), 5)
        XCTAssertEqual(UsageWordCounter.countWords(in: ""), 0)
    }

    func testRecordPersistsAggregateCountsWithoutTranscriptText() throws {
        let transcript = "Hello from Yoing today"
        let event = DictationUsageEvent(
            transcript: transcript,
            dictatedSeconds: 12,
            provider: "xAI",
            date: date(year: 2026, month: 6, day: 8, hour: 10)
        )

        try store.record(event)

        let snapshot = store.snapshot(dayCount: 7, now: event.date)
        XCTAssertEqual(snapshot.today.wordCount, 4)
        XCTAssertEqual(snapshot.today.characterCount, transcript.count)
        XCTAssertEqual(snapshot.today.sessionCount, 1)
        XCTAssertEqual(snapshot.today.dictatedSeconds, 12)
        XCTAssertEqual(snapshot.today.providerCounts["xAI"], 1)

        let persistedData = try XCTUnwrap(defaults.data(forKey: UserDefaultsUsageStatsStore.defaultStorageKey))
        let persistedString = try XCTUnwrap(String(data: persistedData, encoding: .utf8))
        XCTAssertFalse(persistedString.contains(transcript))
        XCTAssertFalse(persistedString.contains("Hello"))
        XCTAssertFalse(persistedString.contains("Yoing today"))
    }

    func testRecordsMultipleSessionsIntoLocalDayBucket() throws {
        let first = DictationUsageEvent(
            date: date(year: 2026, month: 6, day: 8, hour: 9),
            wordCount: 10,
            characterCount: 40,
            dictatedSeconds: 20,
            provider: "xAI"
        )
        let second = DictationUsageEvent(
            date: date(year: 2026, month: 6, day: 8, hour: 23),
            wordCount: 15,
            characterCount: 60,
            dictatedSeconds: 30,
            provider: "OpenAI"
        )

        try store.record(first)
        try store.record(second)

        let snapshot = store.snapshot(dayCount: 1, now: second.date)
        XCTAssertEqual(snapshot.today.wordCount, 25)
        XCTAssertEqual(snapshot.today.characterCount, 100)
        XCTAssertEqual(snapshot.today.sessionCount, 2)
        XCTAssertEqual(snapshot.today.dictatedSeconds, 50)
        XCTAssertEqual(snapshot.today.providerCounts["xAI"], 1)
        XCTAssertEqual(snapshot.today.providerCounts["OpenAI"], 1)
    }

    func testSnapshotFillsEmptyDays() throws {
        let now = date(year: 2026, month: 6, day: 8, hour: 10)
        try store.record(
            DictationUsageEvent(
                date: now,
                wordCount: 8,
                characterCount: 24,
                dictatedSeconds: 6,
                provider: "xAI"
            )
        )

        let snapshot = store.snapshot(dayCount: 3, now: now)
        XCTAssertEqual(snapshot.days.count, 3)
        XCTAssertEqual(snapshot.days[0].day, date(year: 2026, month: 6, day: 6))
        XCTAssertEqual(snapshot.days[0].wordCount, 0)
        XCTAssertEqual(snapshot.days[1].day, date(year: 2026, month: 6, day: 7))
        XCTAssertEqual(snapshot.days[1].wordCount, 0)
        XCTAssertEqual(snapshot.days[2].day, date(year: 2026, month: 6, day: 8))
        XCTAssertEqual(snapshot.days[2].wordCount, 8)
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return calendar.date(from: components)!
    }
}

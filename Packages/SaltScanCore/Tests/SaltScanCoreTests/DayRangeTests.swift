import Foundation
import Testing
@testable import SaltScanCore

private let paris: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
    return calendar
}()

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    paris.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

@Suite("DayRange")
struct DayRangeTests {
    @Test("A day runs from midnight to the next midnight, end excluded")
    func bounds() {
        let range = DayRange(containing: date(2026, 9, 29, 15, 30), calendar: paris)
        #expect(range.start == date(2026, 9, 29))
        #expect(range.end == date(2026, 9, 30))
        #expect(range.contains(date(2026, 9, 29, 23, 59)))
        #expect(!range.contains(date(2026, 9, 30)))
        #expect(!range.contains(date(2026, 9, 28, 23, 59)))
    }

    @Test("The spring DST day is 23 hours and still contains its evening")
    func daylightSaving() {
        let range = DayRange(containing: date(2026, 3, 29, 10), calendar: paris)
        #expect(range.end.timeIntervalSince(range.start) == 23 * 3600)
        #expect(range.contains(date(2026, 3, 29, 23, 30)))
    }

    @Test("Shifting moves whole days")
    func shifted() {
        let range = DayRange(containing: date(2026, 9, 29, 8), calendar: paris)
        #expect(range.shifted(byDays: -1, calendar: paris).start == date(2026, 9, 28))
        #expect(range.shifted(byDays: 1, calendar: paris).start == date(2026, 9, 30))
    }
}

@Suite("JournalDay")
struct JournalDayTests {
    let now = date(2026, 9, 29, 18, 45)

    @Test("Today's portions keep the current time")
    func entryToday() {
        #expect(JournalDay.entryDate(for: date(2026, 9, 29, 7), now: now, calendar: paris) == now)
    }

    @Test("Past days get noon, away from midnight")
    func entryPast() {
        #expect(JournalDay.entryDate(for: date(2026, 9, 27, 23, 50), now: now, calendar: paris) == date(2026, 9, 27, 12))
    }

    @Test("A future day falls back to now")
    func entryFuture() {
        #expect(JournalDay.entryDate(for: date(2026, 10, 2), now: now, calendar: paris) == now)
    }

    @Test("Relative labels")
    func relative() {
        #expect(JournalDay.relative(date(2026, 9, 29, 1), now: now, calendar: paris) == .today)
        #expect(JournalDay.relative(date(2026, 9, 28, 23), now: now, calendar: paris) == .yesterday)
        #expect(JournalDay.relative(date(2026, 9, 20), now: now, calendar: paris) == .earlier)
    }

    @Test("Forward navigation stops at today")
    func forward() {
        #expect(JournalDay.canGoForward(from: date(2026, 9, 28), now: now, calendar: paris))
        #expect(!JournalDay.canGoForward(from: date(2026, 9, 29, 3), now: now, calendar: paris))
    }
}

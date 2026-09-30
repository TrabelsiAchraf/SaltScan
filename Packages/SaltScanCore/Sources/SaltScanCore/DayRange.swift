//
//  DayRange.swift
//  SaltScanCore
//
//  Calendar-day boundaries for the journal. Every screen that shows a day's
//  portions filters on the same range, so the Home ring and the lists can
//  never disagree.
//

import Foundation

public struct DayRange: Sendable, Equatable {
    public let start: Date
    /// Next midnight, excluded.
    public let end: Date

    public init(containing date: Date, calendar: Calendar = .current) {
        start = calendar.startOfDay(for: date)
        end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
    }

    public func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    public func shifted(byDays days: Int, calendar: Calendar = .current) -> DayRange {
        DayRange(containing: calendar.date(byAdding: .day, value: days, to: start) ?? start, calendar: calendar)
    }
}

public enum JournalDay {
    public enum Relative: Equatable, Sendable {
        case today
        case yesterday
        case earlier
    }

    /// Timestamp of a portion added to `day`: now for today (or a future day),
    /// noon for a past day so time-zone shifts never move it across midnight.
    public static func entryDate(for day: Date, now: Date = .now, calendar: Calendar = .current) -> Date {
        let target = DayRange(containing: day, calendar: calendar)
        let today = DayRange(containing: now, calendar: calendar)
        guard target.start < today.start else { return now }
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: target.start) ?? target.start
    }

    public static func relative(_ day: Date, now: Date = .now, calendar: Calendar = .current) -> Relative {
        let today = DayRange(containing: now, calendar: calendar)
        if today.contains(day) { return .today }
        if today.shifted(byDays: -1, calendar: calendar).contains(day) { return .yesterday }
        return .earlier
    }

    public static func canGoForward(from day: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        DayRange(containing: day, calendar: calendar).start < DayRange(containing: now, calendar: calendar).start
    }
}

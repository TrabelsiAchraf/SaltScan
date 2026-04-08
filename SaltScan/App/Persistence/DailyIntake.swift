//
//  DailyIntake.swift
//  SaltScan
//
//  SwiftData models for the daily salt journal:
//  - `DailyIntake` is one bucket per calendar day.
//  - `IntakeLine` is a single entry (product + portion in grams) inside that day.
//

import Foundation
import SwiftData

@Model
final class DailyIntake {
    /// Start-of-day date acts as a natural unique key.
    @Attribute(.unique) var day: Date

    @Relationship(deleteRule: .cascade, inverse: \IntakeLine.intake)
    var lines: [IntakeLine] = []

    init(day: Date) {
        self.day = Calendar.current.startOfDay(for: day)
    }

    /// Total salt consumed across all lines, in grams.
    var totalSaltGrams: Double {
        lines.reduce(0) { $0 + $1.saltGrams }
    }
}

@Model
final class IntakeLine {
    var grams: Double
    var addedAt: Date

    var scan: ScanEntry?
    var intake: DailyIntake?

    init(scan: ScanEntry, grams: Double, addedAt: Date = .now) {
        self.scan = scan
        self.grams = grams
        self.addedAt = addedAt
    }

    /// Salt in grams for this portion: (sodium per 100g × 2.5) × (grams / 100).
    var saltGrams: Double {
        guard let sodium100g = scan?.sodium100g else { return 0 }
        return sodium100g * 2.5 * grams / 100
    }
}

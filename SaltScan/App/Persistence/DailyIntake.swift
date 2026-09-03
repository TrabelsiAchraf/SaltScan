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
import SaltScanCore

@Model
final class DailyIntake {
    /// Start-of-day date acts as a natural unique key.
    @Attribute(.unique) var day: Date

    @Relationship(deleteRule: .cascade, inverse: \IntakeLine.intake)
    var lines: [IntakeLine] = []

    init(day: Date) {
        self.day = Calendar.current.startOfDay(for: day)
    }

    /// Total sodium consumed across all lines, in grams.
    var totalSodiumGrams: Double {
        lines.reduce(0) { $0 + $1.sodiumGrams }
    }

    /// Total salt consumed across all lines, in grams.
    var totalSaltGrams: Double {
        SaltMath.salt(fromSodiumGrams: totalSodiumGrams)
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

    /// Sodium in grams for this portion: sodium per 100g × (grams / 100).
    var sodiumGrams: Double {
        guard let sodium100g = scan?.sodium100g else { return 0 }
        return sodium100g * grams / 100
    }

    /// Salt in grams for this portion.
    var saltGrams: Double {
        SaltMath.salt(fromSodiumGrams: sodiumGrams)
    }
}

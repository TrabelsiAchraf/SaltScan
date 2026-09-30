//
//  DailyIntake.swift
//  SaltScan
//
//  SwiftData models for the daily salt journal:
//  - `DailyIntake` is one bucket per calendar day.
//  - `IntakeLine` is a single entry (product copy + portion in grams) inside that day.
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

    // Added in 0.5.0. Optional and without default values so SwiftData
    // migrates older stores automatically; `JournalBackfill` fills them for
    // lines logged before. A default UUID here would give every migrated line
    // the same identifier.
    /// Stable identity of the portion, also its Apple Health sync identifier.
    var lineID: UUID?
    /// Product name when the portion was logged.
    var productName: String?
    /// Sodium grams per 100 g when the portion was logged.
    var sodium100g: Double?
    /// Barcode of the product, to reopen its sheet while it still exists.
    var barcode: String?

    init(scan: ScanEntry, grams: Double, addedAt: Date = .now) {
        self.scan = scan
        self.grams = grams
        self.addedAt = addedAt
        self.lineID = UUID()
        self.productName = scan.productName
        self.sodium100g = scan.sodium100g
        self.barcode = scan.barcode
    }

    /// Fills the 0.5.0 fields of a line logged by an older version. Only
    /// writes fields that are still empty.
    func backfill() {
        if lineID == nil { lineID = UUID() }
        guard let scan else { return }
        if productName == nil { productName = scan.productName }
        if sodium100g == nil { sodium100g = scan.sodium100g }
        if barcode == nil { barcode = scan.barcode }
    }

    /// Name shown in the journal, even after the product left History.
    var displayName: String {
        productName ?? scan?.productName ?? ""
    }

    /// Sodium per 100 g used for totals: the copy taken when the portion was
    /// logged, so rescanning or deleting the product never rewrites past days.
    var effectiveSodium100g: Double? {
        sodium100g ?? scan?.sodium100g
    }

    /// Sodium in grams for this portion: sodium per 100g × (grams / 100).
    var sodiumGrams: Double {
        guard let sodium100g = effectiveSodium100g else { return 0 }
        return sodium100g * grams / 100
    }

    /// Salt in grams for this portion.
    var saltGrams: Double {
        SaltMath.salt(fromSodiumGrams: sodiumGrams)
    }
}

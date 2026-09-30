//
//  JournalStore.swift
//  SaltScan
//
//  The only place that changes the journal. Keeps the day bucket, the rating
//  gate and Apple Health in step with every add, edit and delete.
//

import Foundation
import SwiftData
import SaltScanCore

@MainActor
struct JournalStore {
    let context: ModelContext
    var health: HealthSyncService = .shared
    var calendar: Calendar = .current

    @discardableResult
    func add(scan: ScanEntry, grams: Double, day: Date, now: Date = .now) throws -> IntakeLine {
        let line = IntakeLine(scan: scan, grams: grams, addedAt: JournalDay.entryDate(for: day, now: now, calendar: calendar))
        // Insert first, then explicitly establish the relationship. Going
        // through `bucket.lines.append` alone wasn't always notifying @Query
        // observers on the parent screens.
        context.insert(line)
        line.intake = DailyIntake.bucket(for: line.addedAt, in: context)
        try save()
        ReviewGate.recordJournalAdd()
        if let snapshot = line.healthSnapshot { health.sync(snapshot) }
        return line
    }

    /// Changes the amount and, when `day` is another day, moves the portion there.
    func update(_ line: IntakeLine, grams: Double, day: Date, now: Date = .now) throws {
        line.grams = grams
        if !calendar.isDate(line.addedAt, inSameDayAs: day) {
            line.addedAt = JournalDay.entryDate(for: day, now: now, calendar: calendar)
            line.intake = DailyIntake.bucket(for: line.addedAt, in: context)
        }
        try save()
        if let snapshot = line.healthSnapshot { health.sync(snapshot) }
    }

    func delete(_ line: IntakeLine) throws {
        let lineID = line.lineID
        context.delete(line)
        try save()
        if let lineID { health.remove(lineID: lineID) }
    }

    private func save() throws {
        do {
            try context.save()
        } catch {
            // Drop the pending insert/edit/delete so a retry can't persist it twice.
            context.rollback()
            assertionFailure("Journal save failed: \(error)")
            throw error
        }
    }
}

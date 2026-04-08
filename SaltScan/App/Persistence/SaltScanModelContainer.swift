//
//  SaltScanModelContainer.swift
//  SaltScan
//
//  Shared SwiftData container factory. Falls back to an in-memory store if
//  the on-disk store fails to open (e.g. after an incompatible schema change
//  during development), so the app always launches.
//

import Foundation
import SwiftData

enum SaltScanModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            ScanEntry.self,
            DailyIntake.self,
            IntakeLine.self,
        ])
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            )
        } catch {
            assertionFailure("SwiftData on-disk store failed: \(error). Falling back to in-memory.")
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
            } catch {
                fatalError("Unable to create any SwiftData container: \(error)")
            }
        }
    }()
}

// MARK: - Helpers

extension DailyIntake {
    /// Fetch-or-create the bucket for a given day inside a model context.
    @MainActor
    static func bucket(for date: Date, in context: ModelContext) -> DailyIntake {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let predicate = #Predicate<DailyIntake> { $0.day == startOfDay }
        if let existing = try? context.fetch(FetchDescriptor<DailyIntake>(predicate: predicate)).first {
            return existing
        }
        let new = DailyIntake(day: startOfDay)
        context.insert(new)
        return new
    }
}

extension ScanEntry {
    /// Look up a cached scan by barcode.
    @MainActor
    static func cached(barcode: String, in context: ModelContext) -> ScanEntry? {
        let predicate = #Predicate<ScanEntry> { $0.barcode == barcode }
        return try? context.fetch(FetchDescriptor<ScanEntry>(predicate: predicate)).first
    }
}

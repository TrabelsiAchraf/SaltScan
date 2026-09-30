//
//  SaltScanModelContainer.swift
//  SaltScan
//
//  Shared SwiftData container factory. Backs the store up once before the
//  0.5.0 migration, retries a failed open, and as a last resort runs on an
//  in-memory store without ever touching the file on disk.
//

import Foundation
import SwiftData
import SaltScanCore

enum SaltScanModelContainer {
    /// True when the on-disk store could not be opened and the app runs on an
    /// empty in-memory store. The file on disk is left exactly as it was, so a
    /// later version can still open it.
    private(set) static var didFallBackToMemory = false

    private static let backupDoneKey = "storeBackupPre050Done"

    static let shared: ModelContainer = {
        let schema = Schema([
            ScanEntry.self,
            DailyIntake.self,
            IntakeLine.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        backUpStoreOnce(at: configuration.url)

        var lastError: Error?
        for _ in 0..<2 {
            do {
                return try ModelContainer(for: schema, configurations: configuration)
            } catch {
                lastError = error
            }
        }

        assertionFailure("SwiftData on-disk store failed: \(String(describing: lastError)). Falling back to in-memory.")
        didFallBackToMemory = true
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("Unable to create any SwiftData container: \(error)")
        }
    }()

    /// Copies the store once, before the first 0.5.0 launch opens (and
    /// migrates) it. A failed copy is retried at the next launch and never
    /// blocks this one.
    private static func backUpStoreOnce(at storeURL: URL) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: backupDoneKey) else { return }
        let backupDirectory = URL.applicationSupportDirectory
            .appending(path: "Backups/pre-0.5.0", directoryHint: .isDirectory)
        do {
            try StoreBackup.backupIfNeeded(storeURL: storeURL, backupDirectory: backupDirectory)
            defaults.set(true, forKey: backupDoneKey)
        } catch {
            print("Store backup failed: \(error)")
        }
    }
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

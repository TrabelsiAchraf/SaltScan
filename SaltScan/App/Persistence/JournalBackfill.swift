//
//  JournalBackfill.swift
//  SaltScan
//
//  Gives journal lines logged before 0.5.0 their stable identifier and their
//  copy of the product name and sodium. Runs at every launch and finds
//  nothing to do once the store is up to date. Never deletes anything and
//  never changes an amount or a date.
//

import Foundation
import SwiftData

enum JournalBackfill {
    /// Returns the number of lines updated.
    @MainActor
    @discardableResult
    static func run(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<IntakeLine>(predicate: #Predicate { $0.lineID == nil })
        guard let lines = try? context.fetch(descriptor), !lines.isEmpty else { return 0 }
        lines.forEach { $0.backfill() }
        do {
            try context.save()
        } catch {
            assertionFailure("Journal backfill failed: \(error)")
            return 0
        }
        return lines.count
    }
}

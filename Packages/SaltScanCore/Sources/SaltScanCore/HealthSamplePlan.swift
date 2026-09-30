//
//  HealthSamplePlan.swift
//  SaltScanCore
//
//  HealthKit-free decisions for the Apple Health export: what to write for a
//  journal portion, under which sync identifier, and in which batches. Health
//  replaces a sample that has the same sync identifier and a higher version,
//  which is what keeps exports free of duplicates.
//

import Foundation

public enum HealthSampleAction: Equatable, Sendable {
    case write(sodiumMilligrams: Double)
    case delete
}

public enum HealthSamplePlan {
    public static let syncIdentifierPrefix = "saltscan.line."
    public static let batchSize = 500

    public static func syncIdentifier(lineID: UUID) -> String {
        syncIdentifierPrefix + lineID.uuidString.lowercased()
    }

    /// Write when the portion has sodium, otherwise make sure no sample is left.
    public static func action(sodiumGrams: Double?) -> HealthSampleAction {
        guard let sodiumGrams, sodiumGrams.isFinite, sodiumGrams > 0 else { return .delete }
        return .write(sodiumMilligrams: sodiumGrams * 1000)
    }

    public static func syncVersion(at date: Date) -> Int {
        Int((date.timeIntervalSince1970 * 1000).rounded(.down))
    }

    public static func batches<T>(_ items: [T], size: Int = batchSize) -> [[T]] {
        guard !items.isEmpty else { return [] }
        guard size > 0 else { return [items] }
        return stride(from: 0, to: items.count, by: size).map {
            Array(items[$0..<min($0 + size, items.count)])
        }
    }
}

//
//  HealthSyncService.swift
//  SaltScan
//
//  Opt-in, write-only export of journal portions to Apple Health as dietary
//  sodium. Each portion is one sample whose sync identifier is the portion's
//  `lineID`, so an edit replaces the sample and an export never duplicates.
//  Never blocks the journal: failures are only logged.
//

import Foundation
import HealthKit
import SaltScanCore

/// What Health needs to know about a portion, detached from the model context.
struct HealthLineSnapshot: Sendable {
    let lineID: UUID
    let sodiumGrams: Double?
    let date: Date
    let productName: String
}

extension IntakeLine {
    var healthSnapshot: HealthLineSnapshot? {
        guard let lineID else { return nil }
        return HealthLineSnapshot(
            lineID: lineID,
            sodiumGrams: effectiveSodium100g.map { $0 * grams / 100 },
            date: addedAt,
            productName: displayName
        )
    }
}

@MainActor
final class HealthSyncService: ObservableObject {
    static let shared = HealthSyncService()

    /// `@AppStorage` keys shared with Settings.
    static let enabledKey = "healthExportEnabled"
    static let lastExportCountKey = "healthLastExportCount"

    /// 0…1 while the one-time export of the journal runs, nil otherwise.
    @Published private(set) var exportProgress: Double?

    private let store = HKHealthStore()
    private let sodiumType = HKQuantityType(.dietarySodium)

    /// Last queued sync or removal; each new one waits for it so a save never lands after a later delete.
    private var pending: Task<Void, Never>?

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    var isEnabled: Bool { UserDefaults.standard.bool(forKey: Self.enabledKey) }

    /// Asks for write access to dietary sodium. True only when it is granted.
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [sodiumType], read: [])
        } catch {
            print("Health authorization failed: \(error)")
            return false
        }
        return store.authorizationStatus(for: sodiumType) == .sharingAuthorized
    }

    /// Writes, replaces or removes the sample of a portion. No-op when the export is off.
    func sync(_ snapshot: HealthLineSnapshot) {
        guard isEnabled else { return }
        let now = Date.now
        enqueue { await $0.apply(snapshot, now: now) }
    }

    /// Removes the sample of a deleted portion. No-op when the export is off.
    func remove(lineID: UUID) {
        guard isEnabled else { return }
        enqueue { service in
            do {
                try await service.deleteSample(lineID: lineID)
            } catch {
                print("Health delete failed for \(lineID): \(error)")
            }
        }
    }

    /// One-time export of the whole journal. Returns the number of samples written.
    @discardableResult
    func exportAll(_ snapshots: [HealthLineSnapshot]) async -> Int {
        let now = Date.now
        let samples = snapshots.compactMap { makeSample($0, now: now) }
        let batches = HealthSamplePlan.batches(samples)
        exportProgress = 0
        defer { exportProgress = nil }
        var written = 0
        for (index, batch) in batches.enumerated() {
            do {
                try await store.save(batch)
                written += batch.count
            } catch {
                print("Health export batch \(index) failed: \(error)")
            }
            exportProgress = Double(index + 1) / Double(batches.count)
        }
        UserDefaults.standard.set(written, forKey: Self.lastExportCountKey)
        return written
    }

    // MARK: - Private

    private func enqueue(_ operation: @escaping @MainActor (HealthSyncService) async -> Void) {
        pending = Task { [previous = pending] in
            await previous?.value
            await operation(self)
        }
    }

    private func apply(_ snapshot: HealthLineSnapshot, now: Date) async {
        do {
            if let sample = makeSample(snapshot, now: now) {
                try await store.save(sample)
            } else {
                try await deleteSample(lineID: snapshot.lineID)
            }
        } catch {
            print("Health sync failed for \(snapshot.lineID): \(error)")
        }
    }

    private func makeSample(_ snapshot: HealthLineSnapshot, now: Date) -> HKQuantitySample? {
        guard case .write(let milligrams) = HealthSamplePlan.action(sodiumGrams: snapshot.sodiumGrams) else {
            return nil
        }
        var metadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: HealthSamplePlan.syncIdentifier(lineID: snapshot.lineID),
            HKMetadataKeySyncVersion: HealthSamplePlan.syncVersion(at: now),
        ]
        if !snapshot.productName.isEmpty {
            metadata[HKMetadataKeyFoodType] = snapshot.productName
        }
        return HKQuantitySample(
            type: sodiumType,
            quantity: HKQuantity(unit: .gramUnit(with: .milli), doubleValue: milligrams),
            start: snapshot.date,
            end: snapshot.date,
            metadata: metadata
        )
    }

    private func deleteSample(lineID: UUID) async throws {
        let predicate = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeySyncIdentifier,
            allowedValues: [HealthSamplePlan.syncIdentifier(lineID: lineID)]
        )
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.deleteObjects(of: sodiumType, predicate: predicate) { _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

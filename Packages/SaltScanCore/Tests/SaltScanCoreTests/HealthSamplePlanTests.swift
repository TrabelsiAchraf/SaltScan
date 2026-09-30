import Foundation
import Testing
@testable import SaltScanCore

@Suite("HealthSamplePlan")
struct HealthSamplePlanTests {
    @Test("Sync identifier is stable and prefixed")
    func identifier() {
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
        #expect(HealthSamplePlan.syncIdentifier(lineID: id) == "saltscan.line.e621e1f8-c36c-495a-93fc-0c247a3e6e5f")
    }

    @Test("Positive sodium is written in milligrams")
    func writes() {
        guard case .write(let milligrams) = HealthSamplePlan.action(sodiumGrams: 0.568) else {
            Issue.record("expected a write")
            return
        }
        #expect(abs(milligrams - 568) < 1e-9)
    }

    @Test("No sodium, zero or nonsense removes the sample")
    func noSodiumDeletes() {
        #expect(HealthSamplePlan.action(sodiumGrams: nil) == .delete)
        #expect(HealthSamplePlan.action(sodiumGrams: 0) == .delete)
        #expect(HealthSamplePlan.action(sodiumGrams: -1) == .delete)
        #expect(HealthSamplePlan.action(sodiumGrams: .nan) == .delete)
    }

    @Test("Version is milliseconds since 1970, so later writes win")
    func version() {
        #expect(HealthSamplePlan.syncVersion(at: Date(timeIntervalSince1970: 1)) == 1000)
        #expect(HealthSamplePlan.syncVersion(at: Date(timeIntervalSince1970: 2)) > HealthSamplePlan.syncVersion(at: Date(timeIntervalSince1970: 1.5)))
    }

    @Test("Batches of 500")
    func batches() {
        #expect(HealthSamplePlan.batches(Array(0..<1001)).map(\.count) == [500, 500, 1])
        #expect(HealthSamplePlan.batches([Int]()).isEmpty)
        #expect(HealthSamplePlan.batches(Array(0..<3), size: 0).map(\.count) == [3])
    }
}

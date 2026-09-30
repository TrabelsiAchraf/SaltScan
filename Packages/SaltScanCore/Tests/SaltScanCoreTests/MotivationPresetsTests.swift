import Testing
@testable import SaltScanCore

@Suite("MotivationPresets")
struct MotivationPresetsTests {
    @Test("Sodium users: AHA for blood pressure and heart, 2,000 mg for kidneys, FDA otherwise")
    func sodium() {
        #expect(MotivationPresets.goal(for: .bloodPressure, unit: .sodiumMilligrams, regionCode: "US").kind == .aha)
        #expect(MotivationPresets.goal(for: .heart, unit: .sodiumMilligrams, regionCode: "US").kind == .aha)
        #expect(MotivationPresets.goal(for: .kidneys, unit: .sodiumMilligrams, regionCode: "CA").kind == .whoSodium)
        #expect(MotivationPresets.goal(for: .pregnancy, unit: .sodiumMilligrams, regionCode: "US").kind == .fda)
        #expect(MotivationPresets.goal(for: .healthierEating, unit: .sodiumMilligrams, regionCode: "US").kind == .fda)
    }

    @Test("Salt users: WHO 5 g, except UK 6 g for pregnancy and healthier eating in GB and IE")
    func salt() {
        #expect(MotivationPresets.goal(for: .bloodPressure, unit: .saltGrams, regionCode: "GB").kind == .who)
        #expect(MotivationPresets.goal(for: .kidneys, unit: .saltGrams, regionCode: "FR").kind == .who)
        #expect(MotivationPresets.goal(for: .pregnancy, unit: .saltGrams, regionCode: "GB").kind == .uk)
        #expect(MotivationPresets.goal(for: .healthierEating, unit: .saltGrams, regionCode: "ie").kind == .uk)
        #expect(MotivationPresets.goal(for: .healthierEating, unit: .saltGrams, regionCode: "FR").kind == .who)
        #expect(MotivationPresets.goal(for: .pregnancy, unit: .saltGrams, regionCode: nil).kind == .who)
    }

    @Test("Goals are stored in grams of salt")
    func values() {
        #expect(MotivationPresets.goal(for: .heart, unit: .sodiumMilligrams, regionCode: "US").saltGrams == 3.75)
        #expect(MotivationPresets.goal(for: .pregnancy, unit: .sodiumMilligrams, regionCode: "US").saltGrams == 5.75)
        #expect(MotivationPresets.goal(for: .pregnancy, unit: .saltGrams, regionCode: "GB").saltGrams == 6)
    }

    @Test("Every motivation's goal is one of the unit's presets, so Settings highlights it")
    func matchesPresets() {
        for unit in SaltUnit.allCases {
            let kinds = GoalPresets.presets(for: unit).map(\.kind)
            for motivation in SaltMotivation.allCases {
                for region in ["US", "GB", "FR", nil] as [String?] {
                    #expect(kinds.contains(MotivationPresets.goal(for: motivation, unit: unit, regionCode: region).kind))
                }
            }
        }
    }
}

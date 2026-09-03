import Foundation
import Testing
@testable import SaltScanCore

private let us = Locale(identifier: "en_US")
private let fr = Locale(identifier: "fr_FR")

@Suite("SaltFormatter")
struct SaltFormatterTests {
    @Test("Salt mode shows grams of salt, two decimals per product")
    func saltDetail() {
        let f = SaltFormatter(unit: .saltGrams, locale: us)
        #expect(f.amount(sodiumGrams: 0.568) == "1.42 g")
    }

    @Test("Salt mode shows one decimal for daily totals")
    func saltTotal() {
        let f = SaltFormatter(unit: .saltGrams, locale: us)
        #expect(f.amount(sodiumGrams: 2.96, precision: .total) == "7.4 g")
    }

    @Test("Sodium mode shows whole milligrams with grouping")
    func sodiumDetail() {
        let f = SaltFormatter(unit: .sodiumMilligrams, locale: us)
        #expect(f.amount(sodiumGrams: 0.568) == "568 mg")
        #expect(f.amount(sodiumGrams: 2.323) == "2,323 mg")
    }

    @Test("Tiny sodium amounts keep one decimal")
    func sodiumTiny() {
        let f = SaltFormatter(unit: .sodiumMilligrams, locale: us)
        #expect(f.amount(sodiumGrams: 0.0083) == "8.3 mg")
        #expect(f.amount(sodiumGrams: 0) == "0 mg")
    }

    @Test("Sodium-only never converts to salt")
    func sodiumOnly() {
        #expect(SaltFormatter(unit: .saltGrams, locale: us).sodiumOnly(sodiumGrams: 0.568) == "0.568 g")
        #expect(SaltFormatter(unit: .sodiumMilligrams, locale: us).sodiumOnly(sodiumGrams: 0.568) == "568 mg")
    }

    @Test("Goals stored in grams of salt render in the user's unit")
    func goals() {
        #expect(SaltFormatter(unit: .saltGrams, locale: us).goal(saltGrams: 5) == "5.0 g")
        #expect(SaltFormatter(unit: .sodiumMilligrams, locale: us).goal(saltGrams: 5) == "2,000 mg")
        #expect(SaltFormatter(unit: .sodiumMilligrams, locale: us).goal(saltGrams: 5.75) == "2,300 mg")
    }

    @Test("French locale uses its own separators")
    func frenchLocale() {
        let f = SaltFormatter(unit: .sodiumMilligrams, locale: fr)
        let text = f.goal(saltGrams: 5.75)
        #expect(text.hasSuffix(" mg"))
        #expect(text.contains("2") && text.contains("300"))
        #expect(!text.contains(","))
        #expect(SaltFormatter(unit: .saltGrams, locale: fr).amount(sodiumGrams: 0.568) == "1,42 g")
    }

    @Test("Unit symbols can be localized")
    func symbols() {
        let ar = Locale(identifier: "ar_SA")
        let f = SaltFormatter(unit: .saltGrams, locale: ar, gramSymbol: "غ", milligramSymbol: "ملغ")
        #expect(f.amount(sodiumGrams: 0.568).hasSuffix(" غ"))
        #expect(SaltFormatter(unit: .sodiumMilligrams, locale: ar, gramSymbol: "غ", milligramSymbol: "ملغ").amount(sodiumGrams: 0.568).hasSuffix(" ملغ"))
    }

    @Test("Percent of the FDA daily value")
    func dailyValue() {
        let f = SaltFormatter(unit: .sodiumMilligrams, locale: us)
        #expect(f.percentOfDailyValue(sodiumGrams: 0.568) == 25)
        #expect(f.percentOfDailyValue(sodiumGrams: 2.3) == 100)
        #expect(f.percentOfDailyValue(sodiumGrams: 0.115) == 5)
    }
}

@Suite("SaltUnitPreference")
struct SaltUnitPreferenceTests {
    @Test("Automatic follows the region")
    func automatic() {
        #expect(SaltUnitPreference.automatic.resolved(regionCode: "US") == .sodiumMilligrams)
        #expect(SaltUnitPreference.automatic.resolved(regionCode: "ca") == .sodiumMilligrams)
        #expect(SaltUnitPreference.automatic.resolved(regionCode: "GB") == .saltGrams)
        #expect(SaltUnitPreference.automatic.resolved(regionCode: "FR") == .saltGrams)
        #expect(SaltUnitPreference.automatic.resolved(regionCode: nil) == .saltGrams)
    }

    @Test("Explicit choices ignore the region")
    func explicit() {
        #expect(SaltUnitPreference.saltGrams.resolved(regionCode: "US") == .saltGrams)
        #expect(SaltUnitPreference.sodiumMilligrams.resolved(regionCode: "FR") == .sodiumMilligrams)
    }
}

@Suite("GoalPresets")
struct GoalPresetsTests {
    @Test("Sodium presets convert to grams of salt")
    func sodiumPresets() {
        let presets = GoalPresets.presets(for: .sodiumMilligrams)
        #expect(presets.map(\.kind) == [.aha, .whoSodium, .fda])
        #expect(presets.map(\.saltGrams) == [3.75, 5.0, 5.75])
    }

    @Test("Salt presets are WHO and UK")
    func saltPresets() {
        #expect(GoalPresets.presets(for: .saltGrams).map(\.saltGrams) == [5, 6])
    }

    @Test("Sodium slider covers 800 to 4,000 mg in 100 mg steps")
    func sodiumSlider() {
        let (range, step) = GoalPresets.sliderRange(for: .sodiumMilligrams)
        #expect(SaltMath.sodium(fromSaltGrams: range.lowerBound) * 1000 == 800)
        #expect(SaltMath.sodium(fromSaltGrams: range.upperBound) * 1000 == 4000)
        #expect(SaltMath.sodium(fromSaltGrams: step) * 1000 == 100)
    }
}

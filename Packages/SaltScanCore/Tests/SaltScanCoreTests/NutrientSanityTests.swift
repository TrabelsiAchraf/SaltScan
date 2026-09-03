import Foundation
import Testing
@testable import SaltScanCore

@Suite("NutrientSanity")
struct NutrientSanityTests {
    @Test("Plain values pass through")
    func ok() {
        let r = NutrientSanity.evaluate(.init(sodium100g: 0.568, energyKcal100g: 498, categories: ["en:snacks", "en:chips"]))
        #expect(r == .init(sodium100g: 0.568, verdict: .ok))
    }

    @Test("Salt fills in when sodium is missing")
    func saltFallback() {
        let r = NutrientSanity.evaluate(.init(sodium100g: nil, salt100g: 1.0))
        #expect(r.sodium100g == 0.4)
        #expect(r.verdict == .ok)
    }

    @Test("Above pure salt is impossible and dropped")
    func impossible() {
        let r = NutrientSanity.evaluate(.init(sodium100g: 45))
        #expect(r == .init(sodium100g: nil, verdict: .impossible))
        #expect(NutrientSanity.evaluate(.init(sodium100g: -1)).verdict == .impossible)
    }

    @Test("Impossible sodium recovers from a plausible salt value")
    func impossibleRecoversFromSalt() {
        let r = NutrientSanity.evaluate(.init(sodium100g: 45, salt100g: 2.0))
        #expect(r.sodium100g == 0.8)
        #expect(r.verdict == .ok)
    }

    @Test("A cola with 12.7 g of sodium is suspicious, not high")
    func colaTypedInMilligrams() {
        let r = NutrientSanity.evaluate(.init(sodium100g: 12.676, energyKcal100g: 42, categories: ["en:beverages", "en:carbonated-drinks", "en:sodas"]))
        #expect(r.sodium100g == 12.676)
        #expect(r.verdict == .suspiciousHigh)
    }

    @Test("Bouillon and soy sauce are allowed to be very salty")
    func saltyCategories() {
        #expect(NutrientSanity.evaluate(.init(sodium100g: 16.0, categories: ["en:broths", "en:stock-cubes"])).verdict == .ok)
        #expect(NutrientSanity.evaluate(.init(sodium100g: 6.5, categories: ["en:condiments", "en:sauces", "en:soy-sauces"])).verdict == .ok)
        #expect(NutrientSanity.evaluate(.init(sodium100g: 39.0, categories: ["en:salts"])).verdict == .ok)
    }

    @Test("Cookies with 0.4 mg of sodium look like grams typed as milligrams")
    func cookiesTypedInGrams() {
        let r = NutrientSanity.evaluate(.init(sodium100g: 0.000397, energyKcal100g: 480, categories: ["en:biscuits"]))
        #expect(r.verdict == .suspiciousLow)
    }

    @Test("Water and fruit with near-zero sodium are fine")
    func lowEnergyLowSodium() {
        #expect(NutrientSanity.evaluate(.init(sodium100g: 0.0008, energyKcal100g: 0)).verdict == .ok)
        #expect(NutrientSanity.evaluate(.init(sodium100g: 0.001, energyKcal100g: nil)).verdict == .ok)
        #expect(NutrientSanity.evaluate(.init(sodium100g: 0, energyKcal100g: 500)).verdict == .ok)
    }

    @Test("No data at all is simply no data")
    func nothing() {
        #expect(NutrientSanity.evaluate(.init(sodium100g: nil)) == .init(sodium100g: nil, verdict: .ok))
    }
}

@Suite("ServingInfo")
struct ServingInfoTests {
    @Test("Published per-serving sodium wins over derivation")
    func published() {
        let s = ServingInfo(label: "28 g", quantityGrams: 28, sodiumGrams: 0.16)
        #expect(s.sodiumPerServing(sodium100g: 0.571) == 0.16)
    }

    @Test("Derives per-serving sodium from the quantity")
    func derived() {
        let s = ServingInfo(label: "1 Tbsp (17 g)", quantityGrams: 17, sodiumGrams: nil)
        let value = s.sodiumPerServing(sodium100g: 0.72)
        #expect(value != nil)
        #expect(abs((value ?? 0) - 0.1224) < 0.0001)
        #expect(ServingInfo(label: nil, quantityGrams: nil, sodiumGrams: nil).sodiumPerServing(sodium100g: 0.72) == nil)
    }

    @Test("Default journal portion snaps to 5 g steps inside the slider range")
    func defaultPortion() {
        #expect(ServingInfo(label: nil, quantityGrams: 28, sodiumGrams: nil).defaultPortionGrams() == 30)
        #expect(ServingInfo(label: nil, quantityGrams: 62.369, sodiumGrams: nil).defaultPortionGrams() == 60)
        #expect(ServingInfo(label: nil, quantityGrams: 3, sodiumGrams: nil).defaultPortionGrams() == nil)
        #expect(ServingInfo(label: nil, quantityGrams: 900, sodiumGrams: nil).defaultPortionGrams() == nil)
        #expect(ServingInfo(label: nil, quantityGrams: nil, sodiumGrams: 0.1).defaultPortionGrams() == nil)
    }
}

@Suite("LenientDouble")
struct LenientDoubleTests {
    private struct Box: Decodable { let v: LenientDouble? }

    private func decode(_ json: String) throws -> Double? {
        try JSONDecoder().decode(Box.self, from: Data(json.utf8)).v?.value
    }

    @Test("Numbers, numeric strings and comma decimals decode")
    func decodes() throws {
        #expect(try decode(#"{"v": 28}"#) == 28)
        #expect(try decode(#"{"v": "28"}"#) == 28)
        #expect(try decode(#"{"v": "0,5"}"#) == 0.5)
        #expect(try decode(#"{"v": " 1.5 "}"#) == 1.5)
    }

    @Test("Garbage, null and missing keys become nil without throwing")
    func tolerates() throws {
        #expect(try decode(#"{"v": "about one cup"}"#) == nil)
        #expect(try decode(#"{"v": null}"#) == nil)
        #expect(try decode(#"{}"#) == nil)
    }
}

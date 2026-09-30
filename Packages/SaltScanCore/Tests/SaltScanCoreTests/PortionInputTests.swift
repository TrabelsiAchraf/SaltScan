import Foundation
import Testing
@testable import SaltScanCore

private let us = Locale(identifier: "en_US")
private let fr = Locale(identifier: "fr_FR")
private let ar = Locale(identifier: "ar")

@Suite("PortionInput")
struct PortionInputTests {
    @Test("Exact half servings are recognised, others are not")
    func exactServings() {
        #expect(PortionInput.exactServings(grams: 42, servingGrams: 28) == 1.5)
        #expect(PortionInput.exactServings(grams: 28, servingGrams: 28) == 1)
        #expect(PortionInput.exactServings(grams: 40, servingGrams: 28) == nil)
        #expect(PortionInput.exactServings(grams: 600, servingGrams: 28) == nil) // 21.4 servings, out of range
        #expect(PortionInput.exactServings(grams: 42, servingGrams: 0) == nil)
    }

    @Test("Nearest half serving is clamped to ½…20")
    func nearestServings() {
        #expect(PortionInput.nearestServings(grams: 40, servingGrams: 28) == 1.5)
        #expect(PortionInput.nearestServings(grams: 5, servingGrams: 28) == 0.5)
        #expect(PortionInput.nearestServings(grams: 1000, servingGrams: 28) == 20)
    }

    @Test("Adding opens on servings when the serving is known; editing only for whole half servings")
    func initialMode() {
        #expect(PortionInput.initialMode(editingGrams: nil, servingGrams: 28) == .servings)
        #expect(PortionInput.initialMode(editingGrams: nil, servingGrams: nil) == .grams)
        #expect(PortionInput.initialMode(editingGrams: nil, servingGrams: 0) == .grams)
        #expect(PortionInput.initialMode(editingGrams: 42, servingGrams: 28) == .servings)
        #expect(PortionInput.initialMode(editingGrams: 40, servingGrams: 28) == .grams)
    }

    @Test("Stepper moves by ½ and stays inside the range")
    func step() {
        #expect(PortionInput.step(1, by: 1) == 1.5)
        #expect(PortionInput.step(0.5, by: -1) == 0.5)
        #expect(PortionInput.step(20, by: 1) == 20)
    }

    @Test("Typed grams must be between 1 and 2,000")
    func validity() {
        #expect(!PortionInput.isValid(grams: nil))
        #expect(!PortionInput.isValid(grams: 0.5))
        #expect(PortionInput.isValid(grams: 1))
        #expect(PortionInput.isValid(grams: 2000))
        #expect(!PortionInput.isValid(grams: 2000.5))
    }

    @Test("Parsing accepts dot, comma and the locale's digits")
    func parseDecimal() {
        #expect(PortionInput.parseGrams("42", locale: us) == 42)
        #expect(PortionInput.parseGrams(" 30 ", locale: us) == 30)
        #expect(PortionInput.parseGrams("42.5", locale: us) == 42.5)
        #expect(PortionInput.parseGrams("42,5", locale: fr) == 42.5)
        #expect(PortionInput.parseGrams("42.5", locale: fr) == 42.5)
        #expect(PortionInput.parseGrams("42,5", locale: us) == 42.5)
    }

    @Test("Parsing reads Arabic-Indic digits")
    func parseArabic() {
        #expect(PortionInput.parseGrams("٤٢", locale: ar) == 42)
    }

    @Test("Parsing rejects empty and non-numeric text")
    func parseInvalid() {
        #expect(PortionInput.parseGrams("", locale: us) == nil)
        #expect(PortionInput.parseGrams("abc", locale: us) == nil)
        #expect(PortionInput.parseGrams("inf", locale: us) == nil)
        #expect(PortionInput.parseGrams("-5", locale: us) == nil)
    }

    @Test("Grams are written without grouping, one decimal at most")
    func formatGrams() {
        #expect(PortionInput.formatGrams(42, locale: us) == "42")
        #expect(PortionInput.formatGrams(42.5, locale: fr) == "42,5")
        #expect(PortionInput.formatGrams(1500, locale: us) == "1500")
    }

    @Test("Round trip: formatted grams parse back to the same value")
    func roundTrip() {
        for locale in [us, fr, ar] {
            #expect(PortionInput.parseGrams(PortionInput.formatGrams(42.5, locale: locale), locale: locale) == 42.5)
        }
    }

    @Test("Servings read as ½, 1, 1½")
    func formatServings() {
        #expect(PortionInput.formatServings(0.5, locale: us) == "½")
        #expect(PortionInput.formatServings(1, locale: us) == "1")
        #expect(PortionInput.formatServings(1.5, locale: us) == "1½")
        #expect(PortionInput.formatServings(20, locale: us) == "20")
    }

    @Test("Shortcuts start with the serving and never repeat a value")
    func shortcuts() {
        #expect(PortionInput.shortcuts(servingGrams: 28).map(\.grams) == [28, 30, 50, 100, 150])
        #expect(PortionInput.shortcuts(servingGrams: 28).first?.isServing == true)
        #expect(PortionInput.shortcuts(servingGrams: nil).map(\.grams) == [30, 50, 100, 150])
        #expect(PortionInput.shortcuts(servingGrams: 50).map(\.grams) == [50, 30, 100, 150])
    }

    @Test("Only a positive serving up to 2,000 g is usable")
    func usableServing() {
        #expect(PortionInput.usableServing(28) == 28)
        #expect(PortionInput.usableServing(nil) == nil)
        #expect(PortionInput.usableServing(0) == nil)
        #expect(PortionInput.usableServing(2500) == nil)
    }
}

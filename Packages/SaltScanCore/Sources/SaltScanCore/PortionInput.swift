//
//  PortionInput.swift
//  SaltScanCore
//
//  Journal portion entry: a number of manufacturer servings in ½ steps, or a
//  typed mass in grams. The journal always stores grams; servings are only a
//  way to type them.
//

import Foundation

public enum PortionMode: String, Sendable, CaseIterable {
    case servings
    case grams
}

/// A one-tap mass in grams mode. `isServing` marks the manufacturer serving.
public struct PortionShortcut: Hashable, Sendable {
    public let grams: Double
    public let isServing: Bool

    public init(grams: Double, isServing: Bool) {
        self.grams = grams
        self.isServing = isServing
    }
}

public enum PortionInput {
    public static let servingStep = 0.5
    public static let servingRange: ClosedRange<Double> = 0.5...20
    public static let gramsRange: ClosedRange<Double> = 1...2000
    /// Quick picks offered in grams mode, after "1 serving" when it is known.
    public static let gramShortcuts: [Double] = [30, 50, 100, 150]
    /// Portion used when the product has no serving size.
    public static let fallbackGrams = 30.0

    /// A serving mass the servings mode can work with, or nil.
    public static func usableServing(_ grams: Double?) -> Double? {
        guard let grams, grams > 0, grams <= gramsRange.upperBound else { return nil }
        return grams
    }

    public static func grams(servings: Double, servingGrams: Double) -> Double {
        servings * servingGrams
    }

    /// Servings for a mass when it is a whole number of half servings inside the range.
    public static func exactServings(grams: Double, servingGrams: Double) -> Double? {
        guard servingGrams > 0 else { return nil }
        let raw = grams / servingGrams
        let halves = (raw / servingStep).rounded() * servingStep
        guard abs(raw - halves) < 0.001, servingRange.contains(halves) else { return nil }
        return halves
    }

    /// Nearest half serving, clamped to the range. Used when switching from grams to servings.
    public static func nearestServings(grams: Double, servingGrams: Double) -> Double {
        guard servingGrams > 0 else { return 1 }
        let halves = ((grams / servingGrams) / servingStep).rounded() * servingStep
        return min(max(halves, servingRange.lowerBound), servingRange.upperBound)
    }

    /// Adding opens on servings when the serving is known. Editing opens on
    /// servings only when the stored mass is a whole number of half servings.
    public static func initialMode(editingGrams: Double?, servingGrams: Double?) -> PortionMode {
        guard let serving = usableServing(servingGrams) else { return .grams }
        guard let editingGrams else { return .servings }
        return exactServings(grams: editingGrams, servingGrams: serving) == nil ? .grams : .servings
    }

    public static func step(_ servings: Double, by delta: Int) -> Double {
        let next = servings + Double(delta) * servingStep
        return min(max(next, servingRange.lowerBound), servingRange.upperBound)
    }

    public static func isValid(grams: Double?) -> Bool {
        guard let grams else { return false }
        return gramsRange.contains(grams)
    }

    /// Reads a typed mass. Accepts "." or "," as decimal separator and the
    /// locale's own digits. Nil when empty, negative or not a number.
    public static func parseGrams(_ text: String, locale: Locale = .current) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let value: Double?
        if let western = Double(trimmed.replacingOccurrences(of: ",", with: ".")) {
            value = western
        } else {
            let formatter = NumberFormatter()
            formatter.locale = locale
            formatter.numberStyle = .decimal
            value = formatter.number(from: trimmed)?.doubleValue

            // Fallback: try Arabic locale with arab numbers format
            if value == nil && locale.identifier.contains("ar") {
                let arabFormatter = NumberFormatter()
                arabFormatter.locale = Locale(identifier: "ar@numbers=arab")
                arabFormatter.numberStyle = .decimal
                return arabFormatter.number(from: trimmed)?.doubleValue
            }
        }
        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }

    /// "42", "42,5": no grouping, one decimal at most, in the locale's digits.
    public static func formatGrams(_ grams: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: grams)) ?? String(format: "%.1f", grams)
    }

    /// "½", "1", "1½": the whole part in the locale's digits, a half as "½".
    public static func formatServings(_ servings: Double, locale: Locale = .current) -> String {
        let whole = Int(servings.rounded(.down))
        let hasHalf = servings - Double(whole) >= 0.25
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let wholeText = (whole == 0 && hasHalf) ? "" : (formatter.string(from: NSNumber(value: whole)) ?? "\(whole)")
        return wholeText + (hasHalf ? "½" : "")
    }

    /// The serving first (when known), then the fixed picks, without duplicates.
    public static func shortcuts(servingGrams: Double?) -> [PortionShortcut] {
        var result: [PortionShortcut] = []
        if let serving = usableServing(servingGrams) {
            result.append(PortionShortcut(grams: serving, isServing: true))
        }
        for grams in gramShortcuts where !result.contains(where: { abs($0.grams - grams) < 0.001 }) {
            result.append(PortionShortcut(grams: grams, isServing: false))
        }
        return result
    }
}

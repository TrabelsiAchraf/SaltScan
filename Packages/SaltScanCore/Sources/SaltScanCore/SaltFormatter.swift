//
//  SaltFormatter.swift
//  SaltScanCore
//
//  Turns a sodium mass (grams) into the string the user expects for their unit.
//

import Foundation

public struct SaltFormatter: Sendable {
    public enum Precision: Sendable {
        /// Daily totals: "7.4 g", "1,850 mg".
        case total
        /// Per product values: "1.42 g", "568 mg".
        case detail
    }

    public let unit: SaltUnit
    public let locale: Locale
    /// Unit symbols, localizable by the caller ("g" / "mg", Arabic "غ" / "ملغ").
    public let gramSymbol: String
    public let milligramSymbol: String

    public init(unit: SaltUnit, locale: Locale = .current, gramSymbol: String = "g", milligramSymbol: String = "mg") {
        self.unit = unit
        self.locale = locale
        self.gramSymbol = gramSymbol
        self.milligramSymbol = milligramSymbol
    }

    /// The quantity the user reads for a sodium mass: salt in grams or sodium in milligrams.
    public func amount(sodiumGrams: Double, precision: Precision = .detail) -> String {
        switch unit {
        case .saltGrams:
            let salt = SaltMath.salt(fromSodiumGrams: sodiumGrams)
            return number(salt, fractionDigits: precision == .total ? 1 : 2) + " " + gramSymbol
        case .sodiumMilligrams:
            return milligrams(sodiumGrams * 1000)
        }
    }

    /// The sodium mass itself, never converted to salt: "0.568 g" or "568 mg".
    public func sodiumOnly(sodiumGrams: Double) -> String {
        switch unit {
        case .saltGrams:
            return number(sodiumGrams, fractionDigits: 3) + " " + gramSymbol
        case .sodiumMilligrams:
            return milligrams(sodiumGrams * 1000)
        }
    }

    /// A daily goal, which the app stores in grams of salt: "5.0 g" or "2,000 mg".
    public func goal(saltGrams: Double) -> String {
        switch unit {
        case .saltGrams:
            return number(saltGrams, fractionDigits: 1) + " " + gramSymbol
        case .sodiumMilligrams:
            return milligrams(SaltMath.sodium(fromSaltGrams: saltGrams) * 1000)
        }
    }

    /// Share of the FDA 2,300 mg daily value, as a rounded percentage.
    public func percentOfDailyValue(sodiumGrams: Double) -> Int {
        Int((sodiumGrams * 1000 / SaltMath.fdaDailySodiumMilligrams * 100).rounded())
    }

    // MARK: - Private

    private func milligrams(_ mg: Double) -> String {
        let digits = (mg > 0 && mg < 10) ? 1 : 0
        return number(mg, fractionDigits: digits) + " " + milligramSymbol
    }

    private func number(_ value: Double, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(fractionDigits)f", value)
    }
}

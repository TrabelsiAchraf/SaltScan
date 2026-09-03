//
//  NutrientSanity.swift
//  SaltScanCore
//
//  Open Food Facts is crowd-sourced. The most common sodium mistakes are
//  milligrams typed as grams (values 1000× too high) and the reverse. This
//  resolves the best available sodium value and flags what looks wrong, so the
//  app never rates a cola "high" with a straight face.
//

import Foundation

public struct NutrientSanity: Sendable {
    public struct Input: Sendable {
        public var sodium100g: Double?
        public var salt100g: Double?
        public var energyKcal100g: Double?
        public var categories: [String]

        public init(sodium100g: Double?, salt100g: Double? = nil, energyKcal100g: Double? = nil, categories: [String] = []) {
            self.sodium100g = sodium100g
            self.salt100g = salt100g
            self.energyKcal100g = energyKcal100g
            self.categories = categories
        }
    }

    public enum Verdict: String, Sendable {
        /// Nothing stands out.
        case ok
        /// Above pure salt: the value is dropped.
        case impossible
        /// Very high for a product that is not a salt, seasoning or sauce.
        case suspiciousHigh
        /// Almost no sodium for an energy-dense processed food.
        case suspiciousLow
    }

    public struct Result: Sendable, Equatable {
        public let sodium100g: Double?
        public let verdict: Verdict
    }

    /// Only salt, seasonings, sauces and stock go beyond this (g of sodium per 100 g).
    public static let highSodiumThreshold = 6.0
    /// Below 2 mg per 100 g for a processed food smells like mg typed as g.
    public static let lowSodiumThreshold = 0.002
    /// Energy above which a food counts as processed for the low check (kcal per 100 g).
    public static let processedFoodEnergyThreshold = 100.0
    /// Category tag fragments for products that are legitimately very salty.
    public static let saltyCategoryMarkers = [
        "salt", "seasoning", "sauce", "broth", "stock", "bouillon", "condiment", "miso",
        "spice", "cured", "pickle", "olive", "anchov", "caper", "brine", "jerky", "dried",
    ]

    public static func evaluate(_ input: Input) -> Result {
        var sodium = input.sodium100g

        if sodium == nil, let salt = input.salt100g {
            sodium = SaltMath.sodium(fromSaltGrams: salt)
        }

        if let value = sodium, value > SaltMath.maxSodiumPer100g {
            if let salt = input.salt100g,
               SaltMath.sodium(fromSaltGrams: salt) <= SaltMath.maxSodiumPer100g {
                sodium = SaltMath.sodium(fromSaltGrams: salt)
            } else {
                return Result(sodium100g: nil, verdict: .impossible)
            }
        }

        if let value = sodium, value < 0 {
            return Result(sodium100g: nil, verdict: .impossible)
        }

        guard let value = sodium else {
            return Result(sodium100g: nil, verdict: .ok)
        }

        let isSaltyCategory = input.categories.contains { tag in
            let lowered = tag.lowercased()
            return saltyCategoryMarkers.contains { lowered.contains($0) }
        }

        if value > highSodiumThreshold, !isSaltyCategory {
            return Result(sodium100g: value, verdict: .suspiciousHigh)
        }
        if value > 0, value < lowSodiumThreshold,
           let kcal = input.energyKcal100g, kcal > processedFoodEnergyThreshold {
            return Result(sodium100g: value, verdict: .suspiciousLow)
        }
        return Result(sodium100g: value, verdict: .ok)
    }
}

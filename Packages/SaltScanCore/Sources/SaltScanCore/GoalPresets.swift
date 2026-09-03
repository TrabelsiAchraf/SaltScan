//
//  GoalPresets.swift
//  SaltScanCore
//
//  Daily goal shortcuts and slider bounds. The goal is always stored in grams
//  of salt; presets that speak in milligrams of sodium are converted.
//

import Foundation

public struct GoalPreset: Identifiable, Sendable, Equatable {
    public enum Kind: String, Sendable {
        /// WHO: under 5 g of salt a day.
        case who
        /// UK: up to 6 g of salt a day.
        case uk
        /// American Heart Association ideal: 1,500 mg of sodium.
        case aha
        /// WHO expressed in sodium: 2,000 mg.
        case whoSodium
        /// FDA daily value: 2,300 mg of sodium.
        case fda
    }

    public let kind: Kind
    public let saltGrams: Double
    public var id: String { kind.rawValue }

    public init(kind: Kind, saltGrams: Double) {
        self.kind = kind
        self.saltGrams = saltGrams
    }
}

public enum GoalPresets {
    public static func presets(for unit: SaltUnit) -> [GoalPreset] {
        switch unit {
        case .saltGrams:
            return [GoalPreset(kind: .who, saltGrams: 5), GoalPreset(kind: .uk, saltGrams: 6)]
        case .sodiumMilligrams:
            return [
                GoalPreset(kind: .aha, saltGrams: SaltMath.salt(fromSodiumGrams: 1.5)),
                GoalPreset(kind: .whoSodium, saltGrams: SaltMath.salt(fromSodiumGrams: 2.0)),
                GoalPreset(kind: .fda, saltGrams: SaltMath.salt(fromSodiumGrams: 2.3)),
            ]
        }
    }

    /// Slider bounds and step, in grams of salt. In sodium mode this is
    /// 800 to 4,000 mg in 100 mg steps.
    public static func sliderRange(for unit: SaltUnit) -> (range: ClosedRange<Double>, step: Double) {
        switch unit {
        case .saltGrams: return (2.0...10.0, 0.5)
        case .sodiumMilligrams: return (2.0...10.0, 0.25)
        }
    }
}

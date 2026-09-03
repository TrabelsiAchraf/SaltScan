//
//  SaltUnit.swift
//  SaltScanCore
//
//  Which quantity the user reads: grams of salt (UK, EU, Australia labels) or
//  milligrams of sodium (US and Canada labels). Everything is stored as sodium
//  in grams per 100 g; only presentation changes.
//

import Foundation

public enum SaltUnit: String, Sendable, CaseIterable {
    /// Grams of salt (sodium chloride).
    case saltGrams
    /// Milligrams of sodium.
    case sodiumMilligrams
}

/// The user's choice in Settings. `automatic` follows the device region.
public enum SaltUnitPreference: String, Sendable, CaseIterable {
    case automatic
    case saltGrams
    case sodiumMilligrams

    /// Regions whose nutrition labels express sodium in milligrams.
    public static let sodiumRegions: Set<String> = ["US", "CA"]

    public func resolved(regionCode: String?) -> SaltUnit {
        switch self {
        case .saltGrams:
            return .saltGrams
        case .sodiumMilligrams:
            return .sodiumMilligrams
        case .automatic:
            guard let regionCode else { return .saltGrams }
            return Self.sodiumRegions.contains(regionCode.uppercased()) ? .sodiumMilligrams : .saltGrams
        }
    }
}

public enum SaltMath {
    /// Salt (NaCl) weighs 2.5 × its sodium. Open Food Facts uses the same factor.
    public static let saltPerSodium = 2.5
    /// FDA daily value for sodium, in milligrams.
    public static let fdaDailySodiumMilligrams = 2300.0
    /// Pure salt is 39.3 g of sodium per 100 g: no food can exceed it.
    public static let maxSodiumPer100g = 39.3

    public static func salt(fromSodiumGrams sodium: Double) -> Double { sodium * saltPerSodium }
    public static func sodium(fromSaltGrams salt: Double) -> Double { salt / saltPerSodium }
}

//
//  ServingInfo.swift
//  SaltScanCore
//
//  Manufacturer serving as published on Open Food Facts, used for per-serving
//  sodium (the US label convention) and as the default journal portion.
//

import Foundation

public struct ServingInfo: Sendable, Equatable {
    /// Free text from the label, e.g. "about 24 chips (28 g)".
    public let label: String?
    /// Serving mass in grams (Open Food Facts normalises ml to g for liquids).
    public let quantityGrams: Double?
    /// Sodium per serving in grams, when the database has it.
    public let sodiumGrams: Double?

    public init(label: String?, quantityGrams: Double?, sodiumGrams: Double?) {
        self.label = label
        self.quantityGrams = quantityGrams
        self.sodiumGrams = sodiumGrams
    }

    public var hasServing: Bool { quantityGrams != nil || sodiumGrams != nil }

    /// Sodium per serving: the published value, else derived from per-100 g data.
    public func sodiumPerServing(sodium100g: Double?) -> Double? {
        if let sodiumGrams { return sodiumGrams }
        if let quantityGrams, quantityGrams > 0, let sodium100g {
            return sodium100g * quantityGrams / 100
        }
        return nil
    }

    /// Default portion for the journal slider (5 to 500 g, 5 g steps), or nil when
    /// the serving is unknown or outside what the slider can show.
    public func defaultPortionGrams() -> Double? {
        guard let quantityGrams, quantityGrams >= 5, quantityGrams <= 500 else { return nil }
        return (quantityGrams / 5).rounded() * 5
    }
}

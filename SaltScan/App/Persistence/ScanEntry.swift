//
//  ScanEntry.swift
//  SaltScan
//
//  SwiftData model persisting a scanned product so the app can show history,
//  favorites and serve cached lookups without re-hitting OpenFoodFacts.
//

import Foundation
import SwiftData
import SaltScanCore

@Model
final class ScanEntry {
    /// Barcode is the stable identity used for cache lookups and dedupe.
    @Attribute(.unique) var barcode: String
    var productName: String
    var brand: String?
    var imageURL: String?

    /// Sodium grams per 100g after `NutrientSanity` (nil when the database
    /// value was impossible). Salt ≈ sodium × 2.5.
    var sodium100g: Double?
    /// Full nutriment snapshot (energy/sugars/sat-fat/proteins per 100g).
    var energyKcal100g: Double?
    var sugars100g: Double?
    var saturatedFat100g: Double?
    var proteins100g: Double?

    /// OFF nutriscore grade: "a".."e" (lowercase).
    var nutriscoreGrade: String?
    var ingredientsText: String?
    var allergens: [String]
    var additives: [String]

    /// Manufacturer serving as published on Open Food Facts.
    var servingSize: String?
    var servingQuantityGrams: Double?
    /// Sodium per serving, grams.
    var sodiumServing: Double?
    /// Raw OFF category tags ("en:sodas"), used by the plausibility checks.
    var categories: [String]?
    /// `NutrientSanity.Verdict` at ingestion time.
    var dataVerdictRaw: String?

    var scannedAt: Date
    var isFavorite: Bool

    /// Back-reference to journal entries that consumed this product.
    @Relationship(deleteRule: .cascade, inverse: \IntakeLine.scan)
    var intakeLines: [IntakeLine] = []

    init(
        barcode: String,
        productName: String,
        brand: String? = nil,
        imageURL: String? = nil,
        sodium100g: Double? = nil,
        energyKcal100g: Double? = nil,
        sugars100g: Double? = nil,
        saturatedFat100g: Double? = nil,
        proteins100g: Double? = nil,
        nutriscoreGrade: String? = nil,
        ingredientsText: String? = nil,
        allergens: [String] = [],
        additives: [String] = [],
        servingSize: String? = nil,
        servingQuantityGrams: Double? = nil,
        sodiumServing: Double? = nil,
        categories: [String]? = nil,
        dataVerdictRaw: String? = nil,
        scannedAt: Date = .now,
        isFavorite: Bool = false
    ) {
        self.barcode = barcode
        self.productName = productName
        self.brand = brand
        self.imageURL = imageURL
        self.sodium100g = sodium100g
        self.energyKcal100g = energyKcal100g
        self.sugars100g = sugars100g
        self.saturatedFat100g = saturatedFat100g
        self.proteins100g = proteins100g
        self.nutriscoreGrade = nutriscoreGrade
        self.ingredientsText = ingredientsText
        self.allergens = allergens
        self.additives = additives
        self.servingSize = servingSize
        self.servingQuantityGrams = servingQuantityGrams
        self.sodiumServing = sodiumServing
        self.categories = categories
        self.dataVerdictRaw = dataVerdictRaw
        self.scannedAt = scannedAt
        self.isFavorite = isFavorite
    }

    /// Severity derived from sodium content, convenient for UI.
    var severity: SSSeverity? {
        guard let sodium100g else { return nil }
        return SSSeverity.fromSodiumPer100g(sodium100g)
    }

    /// Salt per 100g, in grams.
    var saltPer100g: Double? {
        sodium100g.map(SaltMath.salt(fromSodiumGrams:))
    }

    var serving: ServingInfo {
        ServingInfo(label: servingSize, quantityGrams: servingQuantityGrams, sodiumGrams: sodiumServing)
    }

    var dataVerdict: NutrientSanity.Verdict {
        dataVerdictRaw.flatMap(NutrientSanity.Verdict.init(rawValue:)) ?? .ok
    }
}

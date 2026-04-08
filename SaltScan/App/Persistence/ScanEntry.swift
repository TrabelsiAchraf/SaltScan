//
//  ScanEntry.swift
//  SaltScan
//
//  SwiftData model persisting a scanned product so the app can show history,
//  favorites and serve cached lookups without re-hitting OpenFoodFacts.
//

import Foundation
import SwiftData

@Model
final class ScanEntry {
    /// Barcode is the stable identity used for cache lookups and dedupe.
    @Attribute(.unique) var barcode: String
    var productName: String
    var brand: String?
    var imageURL: String?

    /// Sodium grams per 100g as returned by OFF. Salt ≈ sodium × 2.5.
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
        sodium100g.map { $0 * 2.5 }
    }
}

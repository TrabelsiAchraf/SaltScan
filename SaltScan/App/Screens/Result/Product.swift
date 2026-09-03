//
//  Product.swift
//  SaltScan
//
//  OpenFoodFacts product payload (API v2, restricted to the fields we render).
//  Every field beyond product_name / nutriments is optional so partial
//  documents still decode, and numeric fields tolerate the strings the
//  database sometimes serves.
//

import Foundation
import SaltScanCore

// MARK: - Top-level response

struct ProductResponse: Codable {
    let product: Product

    struct Product: Codable {
        let productName: String?
        let brands: String?
        let imageURL: String?
        let imageFrontURL: String?
        let nutriscoreGrade: String?
        let ingredientsText: String?
        let allergensTags: [String]?
        let additivesTags: [String]?
        let categoriesTags: [String]?
        let servingSize: String?
        let servingQuantity: LenientDouble?
        let nutriments: Nutriments?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands
            case imageURL = "image_url"
            case imageFrontURL = "image_front_url"
            case nutriscoreGrade = "nutriscore_grade"
            case ingredientsText = "ingredients_text"
            case allergensTags = "allergens_tags"
            case additivesTags = "additives_tags"
            case categoriesTags = "categories_tags"
            case servingSize = "serving_size"
            case servingQuantity = "serving_quantity"
            case nutriments
        }

        /// Best image URL available.
        var bestImageURL: URL? {
            [imageFrontURL, imageURL]
                .compactMap { $0 }
                .first
                .flatMap(URL.init(string:))
        }

        /// Cleaned allergen labels (remove "en:" locale prefixes).
        var cleanAllergens: [String] {
            (allergensTags ?? []).map { $0.replacingOccurrences(of: "en:", with: "") }
        }

        var cleanAdditives: [String] {
            (additivesTags ?? []).map { $0.replacingOccurrences(of: "en:", with: "") }
        }

        /// Serving mass in grams, when the database has a usable number.
        var servingQuantityGrams: Double? { servingQuantity?.value }
    }
}

/// Open Food Facts v2 envelope. `status` is 1 when the barcode is known.
struct ProductEnvelope: Decodable {
    let status: Int?
    let product: ProductResponse.Product?
}

// MARK: - Nutriments

struct Nutriments: Codable {
    let sodium100g: Double?
    let energyKcal100g: Double?
    let sugars100g: Double?
    let saturatedFat100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    let salt100g: Double?
    /// Sodium per manufacturer serving, in grams.
    let sodiumServing: Double?
    let saltServing: Double?

    enum CodingKeys: String, CodingKey {
        case sodium100g = "sodium_100g"
        case energyKcal100g = "energy-kcal_100g"
        case sugars100g = "sugars_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case salt100g = "salt_100g"
        case sodiumServing = "sodium_serving"
        case saltServing = "salt_serving"
    }

    init(
        sodium100g: Double? = nil,
        energyKcal100g: Double? = nil,
        sugars100g: Double? = nil,
        saturatedFat100g: Double? = nil,
        proteins100g: Double? = nil,
        carbohydrates100g: Double? = nil,
        fat100g: Double? = nil,
        salt100g: Double? = nil,
        sodiumServing: Double? = nil,
        saltServing: Double? = nil
    ) {
        self.sodium100g = sodium100g
        self.energyKcal100g = energyKcal100g
        self.sugars100g = sugars100g
        self.saturatedFat100g = saturatedFat100g
        self.proteins100g = proteins100g
        self.carbohydrates100g = carbohydrates100g
        self.fat100g = fat100g
        self.salt100g = salt100g
        self.sodiumServing = sodiumServing
        self.saltServing = saltServing
    }

    /// Numbers may arrive as strings ("0,5"); decode each field leniently so
    /// one odd value never sinks the whole product.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func number(_ key: CodingKeys) -> Double? {
            (try? container.decodeIfPresent(LenientDouble.self, forKey: key))?.value
        }
        sodium100g = number(.sodium100g)
        energyKcal100g = number(.energyKcal100g)
        sugars100g = number(.sugars100g)
        saturatedFat100g = number(.saturatedFat100g)
        proteins100g = number(.proteins100g)
        carbohydrates100g = number(.carbohydrates100g)
        fat100g = number(.fat100g)
        salt100g = number(.salt100g)
        sodiumServing = number(.sodiumServing)
        saltServing = number(.saltServing)
    }
}

// MARK: - Firebase fallback

struct FirebaseProductResponse: Codable {
    let product_name: String?
    let sodium_100g: Double?
}

extension FirebaseProductResponse {
    func mapToProductResponse() -> ProductResponse {
        .init(
            product: .init(
                productName: product_name,
                brands: nil,
                imageURL: nil,
                imageFrontURL: nil,
                nutriscoreGrade: nil,
                ingredientsText: nil,
                allergensTags: nil,
                additivesTags: nil,
                categoriesTags: nil,
                servingSize: nil,
                servingQuantity: nil,
                nutriments: .init(sodium100g: sodium_100g)
            )
        )
    }
}

// MARK: - ProductResponse → ScanEntry bridge

extension ProductResponse {
    /// Build a `ScanEntry` from a scanned OFF product, ready to persist. Sodium
    /// goes through `NutrientSanity` so impossible values are dropped and
    /// doubtful ones are remembered for the warning banner.
    func makeScanEntry(barcode: String) -> ScanEntry {
        let nutriments = product.nutriments
        let categories = product.categoriesTags ?? []
        let sanity = NutrientSanity.evaluate(.init(
            sodium100g: nutriments?.sodium100g,
            salt100g: nutriments?.salt100g,
            energyKcal100g: nutriments?.energyKcal100g,
            categories: categories
        ))
        let sodiumServing: Double? = sanity.verdict == .impossible
            ? nil
            : nutriments?.sodiumServing ?? nutriments?.saltServing.map(SaltMath.sodium(fromSaltGrams:))

        return ScanEntry(
            barcode: barcode,
            productName: product.productName ?? "Unknown",
            brand: product.brands,
            imageURL: product.bestImageURL?.absoluteString,
            sodium100g: sanity.sodium100g,
            energyKcal100g: nutriments?.energyKcal100g,
            sugars100g: nutriments?.sugars100g,
            saturatedFat100g: nutriments?.saturatedFat100g,
            proteins100g: nutriments?.proteins100g,
            nutriscoreGrade: product.nutriscoreGrade?.lowercased(),
            ingredientsText: product.ingredientsText,
            allergens: product.cleanAllergens,
            additives: product.cleanAdditives,
            servingSize: product.servingSize,
            servingQuantityGrams: product.servingQuantityGrams,
            sodiumServing: sodiumServing,
            categories: categories,
            dataVerdictRaw: sanity.verdict.rawValue
        )
    }
}

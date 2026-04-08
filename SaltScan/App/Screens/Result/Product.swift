//
//  Product.swift
//  SaltScan
//
//  OpenFoodFacts product payload. Every field beyond product_name / nutriments
//  is optional so partial documents still decode successfully.
//

import Foundation

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
    }
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

    enum CodingKeys: String, CodingKey {
        case sodium100g = "sodium_100g"
        case energyKcal100g = "energy-kcal_100g"
        case sugars100g = "sugars_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case salt100g = "salt_100g"
    }

    init(
        sodium100g: Double? = nil,
        energyKcal100g: Double? = nil,
        sugars100g: Double? = nil,
        saturatedFat100g: Double? = nil,
        proteins100g: Double? = nil,
        carbohydrates100g: Double? = nil,
        fat100g: Double? = nil,
        salt100g: Double? = nil
    ) {
        self.sodium100g = sodium100g
        self.energyKcal100g = energyKcal100g
        self.sugars100g = sugars100g
        self.saturatedFat100g = saturatedFat100g
        self.proteins100g = proteins100g
        self.carbohydrates100g = carbohydrates100g
        self.fat100g = fat100g
        self.salt100g = salt100g
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
                nutriments: .init(sodium100g: sodium_100g)
            )
        )
    }
}

// MARK: - ProductResponse → ScanEntry bridge

extension ProductResponse {
    /// Build a `ScanEntry` from a scanned OFF product, ready to persist.
    func makeScanEntry(barcode: String) -> ScanEntry {
        ScanEntry(
            barcode: barcode,
            productName: product.productName ?? "Unknown",
            brand: product.brands,
            imageURL: product.bestImageURL?.absoluteString,
            sodium100g: product.nutriments?.sodium100g,
            energyKcal100g: product.nutriments?.energyKcal100g,
            sugars100g: product.nutriments?.sugars100g,
            saturatedFat100g: product.nutriments?.saturatedFat100g,
            proteins100g: product.nutriments?.proteins100g,
            nutriscoreGrade: product.nutriscoreGrade?.lowercased(),
            ingredientsText: product.ingredientsText,
            allergens: product.cleanAllergens,
            additives: product.cleanAdditives
        )
    }
}

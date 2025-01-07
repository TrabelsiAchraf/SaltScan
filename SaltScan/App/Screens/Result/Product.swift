//
//  Product.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import Foundation

struct ProductResponse: Codable {
    let product: Product
    
    struct Product: Codable {
        let productName: String?
        let nutriments: Nutriments?
        
        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case nutriments
        }
    }
}

struct Nutriments: Codable {
    let sodium100g: Double?
    
    enum CodingKeys: String, CodingKey {
        case sodium100g = "sodium_100g"
    }
}

struct FirebaseProductResponse: Codable {
    let product_name: String?
    let sodium_100g: Double?
}

extension FirebaseProductResponse {
    func mapToProductResponse() -> ProductResponse {
        .init(
            product: .init(
                productName: product_name,
                nutriments: .init(sodium100g: sodium_100g)
            )
        )
    }
}

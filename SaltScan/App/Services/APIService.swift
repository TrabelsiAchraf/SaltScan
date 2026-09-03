//
//  APIService.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//
//  Open Food Facts v2 lookups restricted to the fields the app renders
//  (2-3 KB per product instead of 20-150 KB), identified with the User-Agent
//  the project asks for, with a Firestore fallback when the lookup fails.
//

import Foundation

enum APIError: LocalizedError {
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .productNotFound: "result.product.notFound.title".localize
        }
    }
}

final class APIService {
    static let shared = APIService()

    /// Only what the product screen shows; keeps payloads small and fast.
    private static let productFields = [
        "product_name", "brands", "image_url", "image_front_url", "nutriscore_grade",
        "ingredients_text", "allergens_tags", "additives_tags", "nutriments",
        "serving_size", "serving_quantity", "categories_tags",
    ].joined(separator: ",")

    /// Open Food Facts asks every client to identify itself.
    static let userAgent: String = {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        return "SaltScan/\(version) (iOS; \(Constants.contactMail))"
    }()

    /// Shared session with the identifying headers and a short timeout.
    let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.httpAdditionalHeaders = [
            "User-Agent": Self.userAgent,
            "Accept": "application/json",
        ]
        session = URLSession(configuration: config)
    }

    func fetchProduct(byBarcode barcode: String) async throws -> ProductResponse {
        guard var components = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "fields", value: Self.productFields)]
        guard let url = components.url else { throw URLError(.badURL) }

        do {
            let (data, _) = try await session.data(from: url)
            debugNetwork(data: data)
            let envelope = try JSONDecoder().decode(ProductEnvelope.self, from: data)
            guard envelope.status == 1, let product = envelope.product else {
                throw APIError.productNotFound
            }
            return ProductResponse(product: product)
        } catch {
            debugPrint("Open Food Facts lookup failed (\(error.localizedDescription)); trying Firestore")
            return try await fetchProductFromFirebase(byBarcode: barcode)
        }
    }

    private func fetchProductFromFirebase(byBarcode barcode: String) async throws -> ProductResponse {
        try await FirebaseService.shared.fetchProduct(byBarcode: barcode).mapToProductResponse()
    }

    // MARK: - Private

    private func debugNetwork(data: Data) {
#if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON: \(jsonString)")
        }
#endif
    }
}

// MARK: - FirebaseService

import FirebaseFirestore

final class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private init() {}

    func fetchProduct(byBarcode barcode: String) async throws -> FirebaseProductResponse {
        do {
            let document = try await db.collection("products").document(barcode).getDocument()

            guard let data = document.data() else {
                throw APIError.productNotFound
            }

            return try Firestore.Decoder().decode(FirebaseProductResponse.self, from: data)
        } catch {
            print("Firestore Fetch Error: \(error)")
            throw error
        }
    }
}

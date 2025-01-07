//
//  APIService.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import Foundation

final class APIService {
    static let shared = APIService()
    private init() {}
    
    func fetchProduct(byBarcode barcode: String) async throws -> ProductResponse {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        let session = URLSession(configuration: config)
        
        do {
            let (data, _) = try await session.data(from: url)
            debugNetwork(data: data)
            let productResponse = try JSONDecoder().decode(ProductResponse.self, from: data)
            return productResponse
        } catch let error as URLError {
            if error.code == .timedOut { debugPrint("Error: Request timed out") }
            do {
                return try await fetchProductFromFirebase(byBarcode: barcode)
            } catch {
                throw error
            }
        } catch {
            debugPrint("Decoding Error: \(error)")
            do {
                return try await fetchProductFromFirebase(byBarcode: barcode)
            } catch {
                throw error
            }
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

import Foundation
import FirebaseFirestore

final class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private init() {}
    
    func fetchProduct(byBarcode barcode: String) async throws -> FirebaseProductResponse {
        do {
            // Fetch depuis Firestore
            let document = try await db.collection("products").document(barcode).getDocument()
            
            // Vérification si le document existe
            guard let data = document.data() else {
                throw NSError(domain: "Firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Produit non trouvé"])
            }
            
            // Décodage des données Firestore en ProductResponse
            let productResponse = try Firestore.Decoder().decode(FirebaseProductResponse.self, from: data)
            return productResponse
            
        } catch {
            print("Firestore Fetch Error: \(error)")
            throw error
        }
    }
}

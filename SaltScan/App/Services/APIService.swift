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
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        debugNetwork(data: data)
        
        do {
            let productResponse = try JSONDecoder().decode(ProductResponse.self, from: data)
            return productResponse
        } catch {
            print("Decoding Error: \(error)")
            throw error
        }
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

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
            throw error
        } catch {
            debugPrint("Decoding Error: \(error)")
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

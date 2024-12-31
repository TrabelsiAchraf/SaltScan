//
//  ResultViewModel.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//

import Foundation

@MainActor
final class ResultViewModel: ObservableObject {
    @Published var product: ProductResponse?
    @Published var errorMessage: String?
    
    func fetchProduct(scannedCode: String) async {
        do {
            product = try await APIService.shared.fetchProduct(byBarcode: scannedCode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

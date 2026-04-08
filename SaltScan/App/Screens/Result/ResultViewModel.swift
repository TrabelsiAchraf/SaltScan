//
//  ResultViewModel.swift
//  SaltScan
//
//  Fetches product data (with OpenFoodFacts → Firebase fallback), persists the
//  hit into SwiftData so History and Journal can use it, and serves cached
//  lookups when the same barcode has already been scanned.
//

import Foundation
import SwiftData

@MainActor
final class ResultViewModel: ObservableObject {
    @Published var product: ProductResponse?
    @Published var cachedEntry: ScanEntry?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    func fetchProduct(scannedCode: String, context: ModelContext?) async {
        isLoading = true
        defer { isLoading = false }

        // Cache hit: return instantly without re-hitting the network.
        if let context, let cached = ScanEntry.cached(barcode: scannedCode, in: context) {
            cachedEntry = cached
            cached.scannedAt = .now
            try? context.save()
            return
        }

        do {
            let response = try await APIService.shared.fetchProduct(byBarcode: scannedCode)
            product = response
            if let context {
                let entry = response.makeScanEntry(barcode: scannedCode)
                context.insert(entry)
                try? context.save()
                cachedEntry = entry
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

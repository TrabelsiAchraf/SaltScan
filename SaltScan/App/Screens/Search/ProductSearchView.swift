//
//  ProductSearchView.swift
//  SaltScan
//
//  Text-search over OpenFoodFacts — lets users look up products by name when
//  they don't have a barcode at hand.
//

import SwiftUI

struct ProductSearchView: View {
    /// Day a portion added from a result goes to (nil = today).
    var journalDay: Date? = nil

    @StateObject private var viewModel = ProductSearchViewModel()
    @State private var query: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView().padding()
                } else if viewModel.results.isEmpty {
                    SSEmptyState(
                        icon: "magnifyingglass",
                        title: "search.empty.title",
                        message: "search.empty.message"
                    )
                } else {
                    List(viewModel.results, id: \.code) { item in
                        NavigationLink {
                            ProductDetailView(barcode: item.code, journalDay: journalDay)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(item.productName ?? item.code)
                                    .font(SSFont.headline())
                                if let brand = item.brands {
                                    Text(brand)
                                        .font(SSFont.caption())
                                        .foregroundStyle(Color.ssTextSecondary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.ssGroupedBackground)
                }
            }
            .navigationTitle("search.title")
        }
        .searchable(text: $query, prompt: Text("search.prompt"))
        .onSubmit(of: .search) {
            Task { await viewModel.search(query: query) }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class ProductSearchViewModel: ObservableObject {
    @Published var results: [ProductSearchHit] = []
    @Published var isLoading: Bool = false

    func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return }

        isLoading = true
        defer { isLoading = false }

        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)&search_simple=1&json=1&page_size=25&fields=code,product_name,brands"
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await APIService.shared.session.data(from: url)
            let decoded = try JSONDecoder().decode(ProductSearchResponse.self, from: data)
            results = decoded.products.filter { !$0.code.isEmpty }
        } catch {
            results = []
        }
    }
}

// MARK: - Decoding

struct ProductSearchResponse: Codable {
    let products: [ProductSearchHit]
}

struct ProductSearchHit: Codable, Hashable {
    let code: String
    let productName: String?
    let brands: String?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
    }
}

//
//  ProductPickerView.swift
//  SaltScan
//
//  Chooses the product for a new portion on a given day: from History
//  (favorites, recent scans, local search), or through the scanner and the
//  Open Food Facts search, whose product sheet adds to the same day.
//

import SwiftUI
import SwiftData

struct ProductPickerView: View {
    let day: Date

    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\ScanEntry.scannedAt, order: .reverse)])
    private var scans: [ScanEntry]

    @State private var query = ""
    @State private var picked: ScanEntry?
    @State private var showScanner = false
    @State private var showSearch = false

    private var favorites: [ScanEntry] { scans.filter(\.isFavorite) }
    private var recent: [ScanEntry] { Array(scans.prefix(20)) }
    private var matches: [ScanEntry] {
        scans.filter {
            $0.productName.localizedCaseInsensitiveContains(query)
                || ($0.brand?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { showScanner = true } label: {
                        Label("picker.scan", systemImage: "barcode.viewfinder")
                    }
                    Button { showSearch = true } label: {
                        Label("picker.searchOFF", systemImage: "magnifyingglass")
                    }
                }

                if query.isEmpty {
                    if !favorites.isEmpty {
                        Section("picker.favorites") { rows(favorites) }
                    }
                    if !recent.isEmpty {
                        Section("picker.recent") { rows(recent) }
                    }
                } else {
                    Section("picker.results") {
                        if matches.isEmpty {
                            Text("picker.noMatch")
                                .foregroundStyle(Color.ssTextSecondary)
                        } else {
                            rows(matches)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, prompt: Text("picker.searchPrompt"))
            .navigationTitle("picker.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("journal.portion.cancel") { dismiss() }
                }
            }
            .sheet(item: $picked) { scan in
                PortionSheet(mode: .add(scan, day: day), onFinished: { dismiss() })
                    .presentationDetents([.large])
            }
            .fullScreenCover(isPresented: $showScanner) {
                ProductScannerView(journalDay: day)
                    .environment(\.journalAddCompletion, { dismiss() })
            }
            .sheet(isPresented: $showSearch) {
                ProductSearchView(journalDay: day)
                    .environment(\.journalAddCompletion, { dismiss() })
            }
        }
    }

    private func rows(_ entries: [ScanEntry]) -> some View {
        ForEach(entries) { entry in
            Button { picked = entry } label: {
                PickerRow(entry: entry)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct PickerRow: View {
    let entry: ScanEntry
    @Environment(\.saltFormatter) private var formatter

    var body: some View {
        HStack(spacing: SSSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.productName)
                    .font(SSFont.subheadline().weight(.semibold))
                    .foregroundStyle(Color.ssTextPrimary)
                    .lineLimit(1)
                if let brand = entry.brand, !brand.isEmpty {
                    Text(brand)
                        .font(SSFont.caption())
                        .foregroundStyle(Color.ssTextSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let severity = entry.severity {
                SSBadge(severity: severity)
            }
        }
        .contentShape(Rectangle())
    }
}

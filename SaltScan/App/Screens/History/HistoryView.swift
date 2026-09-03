//
//  HistoryView.swift
//  SaltScan
//
//  Lists past scans grouped by day, with search, favorites filter,
//  swipe-to-delete / swipe-to-favorite actions and a compare mode that
//  selects 2 to 4 products for a side-by-side ComparisonView.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\ScanEntry.scannedAt, order: .reverse)])
    private var allEntries: [ScanEntry]

    @State private var searchText: String = ""
    @State private var showFavoritesOnly: Bool = false
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<PersistentIdentifier>()
    @State private var showCompare = false

    private var isComparing: Bool { editMode == .active }
    private var selectedEntries: [ScanEntry] { allEntries.filter { selection.contains($0.id) } }
    private var canCompare: Bool { (2...4).contains(selection.count) }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    SSEmptyState(
                        icon: "clock.arrow.circlepath",
                        title: "history.empty.title",
                        message: "history.empty.message"
                    )
                } else {
                    List(selection: $selection) {
                        ForEach(groupedByDay, id: \.0) { day, entries in
                            Section(header: Text(dayLabel(day)).font(SSFont.subheadline().weight(.semibold))) {
                                ForEach(entries) { entry in
                                    NavigationLink {
                                        ProductDetailView(barcode: entry.barcode, preloadedEntry: entry)
                                    } label: {
                                        HistoryRow(entry: entry)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            entry.isFavorite.toggle()
                                            try? context.save()
                                        } label: {
                                            Label(
                                                entry.isFavorite ? "history.unfavorite" : "history.favorite",
                                                systemImage: entry.isFavorite ? "heart.slash" : "heart.fill"
                                            )
                                        }
                                        .tint(.ssPrimary)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            context.delete(entry)
                                            try? context.save()
                                        } label: {
                                            Label("history.delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.ssGroupedBackground)
                    .environment(\.editMode, $editMode)
                }
            }
            .navigationTitle("history.title")
            .toolbar {
                if allEntries.count >= 2 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            toggleCompareMode()
                        } label: {
                            if isComparing {
                                Text("history.compare.cancel")
                            } else {
                                Label("history.compare.button", systemImage: "rectangle.split.2x1")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundStyle(Color.ssPrimary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text("history.search.prompt"))
            .safeAreaInset(edge: .bottom) {
                if isComparing {
                    compareBar
                }
            }
            .navigationDestination(isPresented: $showCompare) {
                ComparisonView(entries: selectedEntries)
            }
        }
    }

    // MARK: - Compare mode

    private var compareBar: some View {
        VStack(spacing: SSSpacing.xs) {
            Group {
                if canCompare {
                    Text(String(format: "history.compare.count".localize, selection.count))
                } else {
                    Text("history.compare.select.hint")
                }
            }
            .font(SSFont.caption())
            .foregroundStyle(Color.ssTextSecondary)

            SSButton(
                title: "history.compare.action",
                icon: "rectangle.split.2x1",
                isEnabled: canCompare
            ) {
                showCompare = true
            }
        }
        .padding(SSSpacing.md)
        .background(.bar)
    }

    private func toggleCompareMode() {
        withAnimation {
            if isComparing {
                editMode = .inactive
                selection.removeAll()
            } else {
                editMode = .active
            }
        }
    }

    // MARK: - Derivations

    private var filtered: [ScanEntry] {
        allEntries.filter { entry in
            let matchesQuery = searchText.isEmpty
                || entry.productName.localizedCaseInsensitiveContains(searchText)
                || entry.barcode.contains(searchText)
            let matchesFavorite = !showFavoritesOnly || entry.isFavorite
            return matchesQuery && matchesFavorite
        }
    }

    private var groupedByDay: [(Date, [ScanEntry])] {
        let groups = Dictionary(grouping: filtered) { entry in
            Calendar.current.startOfDay(for: entry.scannedAt)
        }
        return groups.sorted { $0.key > $1.key }
    }

    private func dayLabel(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "history.day.today".localize }
        if cal.isDateInYesterday(day) { return "history.day.yesterday".localize }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: day)
    }
}

// MARK: - Row

private struct HistoryRow: View {
    let entry: ScanEntry

    var body: some View {
        HStack(spacing: SSSpacing.sm) {
            if let urlString = entry.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Color.ssSurfaceElevated
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))
            } else {
                RoundedRectangle(cornerRadius: SSRadius.sm)
                    .fill(Color.ssSurfaceElevated)
                    .frame(width: 52, height: 52)
                    .overlay(Image(systemName: "barcode").foregroundStyle(Color.ssTextSecondary))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.productName)
                        .font(SSFont.headline())
                        .lineLimit(1)
                    if entry.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color.ssSeverityHigh)
                            .font(.caption)
                    }
                }
                if let brand = entry.brand, !brand.isEmpty {
                    Text(brand)
                        .font(SSFont.caption())
                        .foregroundStyle(Color.ssTextSecondary)
                }
                if let severity = entry.severity {
                    SSBadge(severity: severity)
                        .padding(.top, 2)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

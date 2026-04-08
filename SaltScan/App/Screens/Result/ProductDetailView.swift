//
//  ProductDetailView.swift
//  SaltScan
//
//  Rich product detail shown after a scan or from the History tab.
//  Features: hero image, nutriscore, severity badge, nutrient grid,
//  allergens/additives, favorite toggle, add-to-journal, share.
//

import SwiftUI
import SwiftData

struct ProductDetailView: View {
    let barcode: String
    /// Preloaded entry (e.g. from History). If nil the view will fetch.
    var preloadedEntry: ScanEntry?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ResultViewModel()
    @State private var showJournalSheet = false

    private var entry: ScanEntry? { preloadedEntry ?? viewModel.cachedEntry }

    var body: some View {
        ScrollView {
            VStack(spacing: SSSpacing.lg) {
                if let entry {
                    heroSection(entry)
                    scoreSection(entry)
                    nutrientsSection(entry)
                    tagsSection(entry)
                    actionsSection(entry)
                } else if viewModel.errorMessage != nil {
                    SSEmptyState(
                        icon: "exclamationmark.triangle",
                        title: "result.product.unknown",
                        message: "result.product.unknown"
                    )
                } else {
                    // Default fallback (also covers the brief moment between
                    // view appearance and the .task firing) so the sheet is
                    // never visually empty.
                    ProgressView("result.product.loading")
                        .padding(.vertical, SSSpacing.xxl)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(SSSpacing.md)
        }
        .background(Color.ssGroupedBackground)
        .navigationTitle("result.product.name")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if preloadedEntry == nil {
                await viewModel.fetchProduct(scannedCode: barcode, context: context)
            }
        }
        .sheet(isPresented: $showJournalSheet) {
            if let entry {
                AddToJournalSheet(scan: entry)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func heroSection(_ entry: ScanEntry) -> some View {
        SSCard(padding: SSSpacing.md) {
            HStack(spacing: SSSpacing.md) {
                productImage(entry)
                VStack(alignment: .leading, spacing: SSSpacing.xxs) {
                    Text(entry.productName)
                        .font(SSFont.title3())
                        .foregroundStyle(Color.ssTextPrimary)
                        .lineLimit(2)
                    if let brand = entry.brand, !brand.isEmpty {
                        Text(brand)
                            .font(SSFont.subheadline())
                            .foregroundStyle(Color.ssTextSecondary)
                    }
                    if let severity = entry.severity {
                        SSBadge(severity: severity)
                            .padding(.top, 2)
                    }
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func productImage(_ entry: ScanEntry) -> some View {
        if let urlString = entry.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundStyle(Color.ssTextSecondary)
                }
            }
            .frame(width: 88, height: 88)
            .background(Color.ssSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))
        } else {
            RoundedRectangle(cornerRadius: SSRadius.sm)
                .fill(Color.ssSurfaceElevated)
                .frame(width: 88, height: 88)
                .overlay(Image(systemName: "takeoutbag.and.cup.and.straw").foregroundStyle(Color.ssTextSecondary))
        }
    }

    @ViewBuilder
    private func scoreSection(_ entry: ScanEntry) -> some View {
        SSCard {
            HStack(spacing: SSSpacing.lg) {
                SSNutriscoreBadge(grade: entry.nutriscoreGrade)
                VStack(alignment: .leading, spacing: 2) {
                    Text("detail.nutriscore.title")
                        .font(SSFont.caption())
                        .foregroundStyle(Color.ssTextSecondary)
                    Text(nutriscoreLabel(entry.nutriscoreGrade))
                        .font(SSFont.headline())
                }
                Spacer()
                if let salt = entry.saltPer100g {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("detail.salt.per100g")
                            .font(SSFont.caption())
                            .foregroundStyle(Color.ssTextSecondary)
                        Text(String(format: "%.2f g", salt))
                            .font(SSFont.title3())
                            .foregroundStyle(entry.severity?.color ?? Color.ssTextPrimary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func nutrientsSection(_ entry: ScanEntry) -> some View {
        SSCard {
            VStack(alignment: .leading, spacing: SSSpacing.xs) {
                SSSectionHeader(title: "detail.nutrients.title")
                    .padding(.bottom, SSSpacing.xs)
                if let v = entry.energyKcal100g {
                    SSNutrientRow(icon: "flame.fill", label: "detail.nutrient.energy", value: String(format: "%.0f kcal", v))
                }
                if let v = entry.sugars100g {
                    SSNutrientRow(icon: "cube.fill", label: "detail.nutrient.sugars", value: String(format: "%.1f g", v))
                }
                if let v = entry.saturatedFat100g {
                    SSNutrientRow(icon: "drop.fill", label: "detail.nutrient.satFat", value: String(format: "%.1f g", v))
                }
                if let v = entry.proteins100g {
                    SSNutrientRow(icon: "fish.fill", label: "detail.nutrient.proteins", value: String(format: "%.1f g", v))
                }
                if let v = entry.sodium100g {
                    SSNutrientRow(
                        icon: "cross.vial.fill",
                        label: "detail.nutrient.sodium",
                        value: String(format: "%.3f g", v),
                        severity: entry.severity
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func tagsSection(_ entry: ScanEntry) -> some View {
        if !entry.allergens.isEmpty || !entry.additives.isEmpty {
            SSCard {
                VStack(alignment: .leading, spacing: SSSpacing.sm) {
                    if !entry.allergens.isEmpty {
                        Text("detail.allergens.title")
                            .font(SSFont.headline())
                        FlowTags(items: entry.allergens, color: .ssSeverityMedium)
                    }
                    if !entry.additives.isEmpty {
                        Text("detail.additives.title")
                            .font(SSFont.headline())
                            .padding(.top, entry.allergens.isEmpty ? 0 : SSSpacing.xs)
                        FlowTags(items: entry.additives, color: .ssAccent)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func actionsSection(_ entry: ScanEntry) -> some View {
        VStack(spacing: SSSpacing.sm) {
            SSButton(
                title: "detail.action.addToJournal",
                icon: "plus.circle.fill",
                style: .primary
            ) {
                showJournalSheet = true
            }
            HStack(spacing: SSSpacing.sm) {
                SSButton(
                    title: entry.isFavorite ? "detail.action.unfavorite" : "detail.action.favorite",
                    icon: entry.isFavorite ? "heart.fill" : "heart",
                    style: .secondary
                ) {
                    entry.isFavorite.toggle()
                    try? context.save()
                }
                ShareLink(
                    item: shareText(entry),
                    preview: SharePreview(entry.productName)
                ) {
                    Label("detail.action.share", systemImage: "square.and.arrow.up")
                        .font(SSFont.subheadline().weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SSSpacing.md)
                        .background(Color.ssSurface)
                        .clipShape(RoundedRectangle(cornerRadius: SSRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: SSRadius.md, style: .continuous)
                                .strokeBorder(Color.ssTextTertiary.opacity(0.25))
                        )
                        .foregroundStyle(Color.ssTextPrimary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func nutriscoreLabel(_ grade: String?) -> String {
        guard let grade = grade?.uppercased() else { return "—" }
        return "Nutriscore \(grade)"
    }

    private func shareText(_ entry: ScanEntry) -> String {
        var parts = [entry.productName]
        if let salt = entry.saltPer100g { parts.append(String(format: "Salt: %.2f g/100g", salt)) }
        if let g = entry.nutriscoreGrade?.uppercased() { parts.append("Nutriscore: \(g)") }
        return parts.joined(separator: " — ")
    }
}

// MARK: - Flow tag layout

private struct FlowTags: View {
    let items: [String]
    var color: Color = .ssPrimary

    var body: some View {
        FlowLayout(spacing: SSSpacing.xs) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(SSFont.caption().weight(.semibold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, SSSpacing.xs)
                    .background(color.opacity(0.15))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        for view in subviews {
            let s = view.sizeThatFits(.unspecified)
            if lineWidth + s.width > maxWidth {
                width = max(width, lineWidth - spacing)
                height += lineHeight + spacing
                lineWidth = s.width + spacing
                lineHeight = s.height
            } else {
                lineWidth += s.width + spacing
                lineHeight = max(lineHeight, s.height)
            }
        }
        width = max(width, lineWidth - spacing)
        height += lineHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for view in subviews {
            let s = view.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            lineHeight = max(lineHeight, s.height)
        }
    }
}

// MARK: - Add to journal sheet

struct AddToJournalSheet: View {
    let scan: ScanEntry

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var grams: Double = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: SSSpacing.lg) {
                Text(scan.productName)
                    .font(SSFont.title3())
                    .multilineTextAlignment(.center)

                SSScoreRing(
                    progress: min(1, grams / 250),
                    value: String(format: "%.0f g", grams),
                    caption: "journal.portion.caption",
                    color: .ssPrimary
                )

                Slider(value: $grams, in: 5...500, step: 5)
                    .tint(Color.ssPrimary)

                if let salt = scan.saltPer100g {
                    Text(String(format: "journal.portion.saltEstimate".localize, salt * grams / 100))
                        .font(SSFont.subheadline())
                        .foregroundStyle(Color.ssTextSecondary)
                }

                SSButton(title: "journal.addPortion", icon: "checkmark.circle.fill") {
                    let bucket = DailyIntake.bucket(for: .now, in: context)
                    let line = IntakeLine(scan: scan, grams: grams)
                    // Insert first, then explicitly establish the relationship.
                    // Going through `bucket.lines.append` alone wasn't always
                    // notifying @Query observers on the parent screens.
                    context.insert(line)
                    line.intake = bucket
                    do {
                        try context.save()
                    } catch {
                        assertionFailure("Failed to save intake: \(error)")
                    }
                    dismiss()
                }
            }
            .padding(SSSpacing.lg)
            .navigationTitle("journal.title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

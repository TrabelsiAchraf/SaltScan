//
//  ProductDetailView.swift
//  SaltScan
//
//  Rich product detail shown after a scan or from the History tab.
//  Features: hero image, nutriscore, severity badge, nutrient grid,
//  allergens/additives, favorite toggle, add-to-journal (PortionSheet), share.
//  Also the place where we ask for an App Store rating, after a positive
//  moment (successful scan or journal entry), gated by ReviewGate.
//

import SwiftUI
import SwiftData
import StoreKit
import SaltScanCore

struct ProductDetailView: View {
    let barcode: String
    /// Preloaded entry (e.g. from History). If nil the view will fetch.
    var preloadedEntry: ScanEntry?
    /// Day the "Add to journal" sheet starts on (nil = today). Set when the
    /// product was opened from the Journal's "+".
    var journalDay: Date? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.journalAddCompletion) private var journalAddCompletion
    @Environment(\.saltFormatter) private var formatter
    @StateObject private var viewModel = ResultViewModel()
    @State private var showJournalSheet = false
    @State private var showSearch = false

    private var entry: ScanEntry? { preloadedEntry ?? viewModel.cachedEntry }

    private var addToOpenFoodFactsURL: URL? {
        URL(string: "https://world.openfoodfacts.org/cgi/product.pl?type=add&code=\(barcode)")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: SSSpacing.lg) {
                if let entry {
                    heroSection(entry)
                    dataWarningSection(entry)
                    scoreSection(entry)
                    servingSection(entry)
                    nutrientsSection(entry)
                    tagsSection(entry)
                    actionsSection(entry)
                } else if viewModel.errorMessage != nil {
                    notFoundSection
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
            .ssReadableWidth()
        }
        .background(Color.ssGroupedBackground)
        .navigationTitle("result.product.name")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard preloadedEntry == nil else { return }
            await viewModel.fetchProduct(scannedCode: barcode, context: context)
            if viewModel.cachedEntry != nil {
                ReviewGate.recordSuccessfulScan()
                // Let the result land before the system rating sheet appears.
                try? await Task.sleep(for: .seconds(2))
                maybeRequestReview()
            }
        }
        .sheet(isPresented: $showJournalSheet, onDismiss: maybeRequestReview) {
            if let entry {
                PortionSheet(mode: .add(entry, day: journalDay ?? .now), onFinished: { journalAddCompletion?() })
                    .presentationDetents([.large])
            }
        }
        .sheet(isPresented: $showSearch) {
            ProductSearchView(journalDay: journalDay)
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
                if let sodium = entry.sodium100g {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(per100gLabelKey)
                            .font(SSFont.caption())
                            .foregroundStyle(Color.ssTextSecondary)
                        Text(formatter.amount(sodiumGrams: sodium))
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
                        value: formatter.sodiumOnly(sodiumGrams: v),
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

    /// "Add to today's journal", or the date when the product was opened for another day.
    private var addToJournalTitle: LocalizedStringKey {
        if let journalDay, JournalDay.relative(journalDay) != .today {
            return LocalizedStringKey(String(
                format: "detail.action.addToJournalOnDay".localize,
                journalDay.formatted(date: .abbreviated, time: .omitted)
            ))
        }
        return "detail.action.addToJournal"
    }

    @ViewBuilder
    private func actionsSection(_ entry: ScanEntry) -> some View {
        VStack(spacing: SSSpacing.sm) {
            SSButton(
                title: addToJournalTitle,
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
                    secondaryLabel("detail.action.share", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    /// Shown when Open Food Facts (and the Firestore fallback) have nothing for
    /// this barcode: offer a way forward instead of a dead end.
    private var notFoundSection: some View {
        VStack(spacing: SSSpacing.md) {
            SSEmptyState(
                icon: "questionmark.circle",
                title: "result.product.notFound.title",
                message: "result.product.notFound.message"
            )
            SSButton(
                title: "result.product.action.searchByName",
                icon: "magnifyingglass",
                style: .primary
            ) {
                showSearch = true
            }
            if let url = addToOpenFoodFactsURL {
                Link(destination: url) {
                    secondaryLabel("result.product.action.addToOFF", systemImage: "plus.circle")
                }
            }
        }
    }

    /// Manufacturer serving with its sodium, and the share of the FDA daily
    /// value when the user reads sodium in milligrams.
    @ViewBuilder
    private func servingSection(_ entry: ScanEntry) -> some View {
        if entry.serving.hasServing,
           let perServing = entry.serving.sodiumPerServing(sodium100g: entry.sodium100g) {
            SSCard {
                HStack(spacing: SSSpacing.lg) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("detail.serving.title")
                            .font(SSFont.caption())
                            .foregroundStyle(Color.ssTextSecondary)
                        if let label = entry.serving.label, !label.isEmpty {
                            Text(String(format: "detail.serving.size".localize, label))
                                .font(SSFont.subheadline())
                        } else if let quantity = entry.serving.quantityGrams {
                            Text(String(format: "detail.serving.size".localize, String(format: "%.0f g", quantity)))
                                .font(SSFont.subheadline())
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatter.amount(sodiumGrams: perServing))
                            .font(SSFont.title3())
                            .foregroundStyle(entry.severity?.color ?? Color.ssTextPrimary)
                        if formatter.unit == .sodiumMilligrams {
                            Text(String(format: "detail.serving.dv".localize, formatter.percentOfDailyValue(sodiumGrams: perServing)))
                                .font(SSFont.caption())
                                .foregroundStyle(Color.ssTextSecondary)
                        }
                    }
                }
            }
        }
    }

    /// Crowd-sourced data sometimes has milligrams typed as grams. Say so
    /// instead of rating a cola "high", and point to where it can be fixed.
    @ViewBuilder
    private func dataWarningSection(_ entry: ScanEntry) -> some View {
        if entry.dataVerdict != .ok {
            SSCard {
                VStack(alignment: .leading, spacing: SSSpacing.xs) {
                    Label("detail.data.suspicious.title", systemImage: "exclamationmark.triangle.fill")
                        .font(SSFont.headline())
                        .foregroundStyle(Color.ssSeverityMedium)
                    Text(warningMessageKey(entry.dataVerdict))
                        .font(SSFont.subheadline())
                        .foregroundStyle(Color.ssTextSecondary)
                    if let url = URL(string: "https://world.openfoodfacts.org/product/\(barcode)") {
                        Link(destination: url) {
                            Label("detail.data.report", systemImage: "pencil.and.list.clipboard")
                                .font(SSFont.subheadline().weight(.semibold))
                        }
                    }
                }
            }
        }
    }

    private func warningMessageKey(_ verdict: NutrientSanity.Verdict) -> LocalizedStringKey {
        switch verdict {
        case .impossible: "detail.data.impossible"
        case .suspiciousHigh: "detail.data.suspicious.high"
        case .suspiciousLow: "detail.data.suspicious.low"
        case .ok: ""
        }
    }

    // MARK: - Helpers

    /// Outlined, full-width label matching `SSButton(style: .secondary)`, for
    /// system controls (ShareLink, Link) that provide their own tap handling.
    private func secondaryLabel(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
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

    private func nutriscoreLabel(_ grade: String?) -> String {
        guard let grade = grade?.uppercased() else { return "—" }
        return "Nutriscore \(grade)"
    }

    private func shareText(_ entry: ScanEntry) -> String {
        var parts = [entry.productName]
        if let sodium = entry.sodium100g {
            let word = formatter.unit == .sodiumMilligrams ? "Sodium" : "Salt"
            parts.append("\(word): \(formatter.amount(sodiumGrams: sodium))/100g")
        }
        if let g = entry.nutriscoreGrade?.uppercased() { parts.append("Nutriscore: \(g)") }
        return parts.joined(separator: " — ")
    }

    private var per100gLabelKey: LocalizedStringKey {
        formatter.unit == .sodiumMilligrams ? "detail.sodium.per100g" : "detail.salt.per100g"
    }

    private func maybeRequestReview() {
#if DEBUG
        if ScreenshotMode.isActive { return }
#endif
        guard ReviewGate.shouldAsk else { return }
        ReviewGate.markAsked()
        requestReview()
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

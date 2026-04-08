//
//  ComparisonView.swift
//  SaltScan
//
//  Side-by-side nutrient comparison between 2-4 previously scanned products.
//

import SwiftUI
import SwiftData

struct ComparisonView: View {
    let entries: [ScanEntry]

    var body: some View {
        ScrollView {
            VStack(spacing: SSSpacing.md) {
                headerRow
                row(label: "compare.salt", values: entries.map { entry in
                    entry.saltPer100g.map { String(format: "%.2f g", $0) } ?? "—"
                })
                row(label: "compare.nutriscore", values: entries.map { $0.nutriscoreGrade?.uppercased() ?? "—" })
                row(label: "compare.sugars", values: entries.map { entry in
                    entry.sugars100g.map { String(format: "%.1f g", $0) } ?? "—"
                })
                row(label: "compare.satFat", values: entries.map { entry in
                    entry.saturatedFat100g.map { String(format: "%.1f g", $0) } ?? "—"
                })
                row(label: "compare.energy", values: entries.map { entry in
                    entry.energyKcal100g.map { String(format: "%.0f kcal", $0) } ?? "—"
                })
            }
            .padding(SSSpacing.md)
        }
        .background(Color.ssGroupedBackground)
        .navigationTitle("compare.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerRow: some View {
        HStack(spacing: SSSpacing.xs) {
            Text("")
                .frame(width: 90, alignment: .leading)
            ForEach(entries) { entry in
                VStack {
                    SSNutriscoreBadge(grade: entry.nutriscoreGrade)
                    Text(entry.productName)
                        .font(SSFont.caption().weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func row(label: LocalizedStringKey, values: [String]) -> some View {
        SSCard(padding: SSSpacing.sm) {
            HStack(spacing: SSSpacing.xs) {
                Text(label)
                    .font(SSFont.subheadline().weight(.semibold))
                    .foregroundStyle(Color.ssTextSecondary)
                    .frame(width: 90, alignment: .leading)
                ForEach(Array(values.enumerated()), id: \.offset) { _, v in
                    Text(v)
                        .font(SSFont.headline())
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

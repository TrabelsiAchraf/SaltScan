//
//  JournalLineRow.swift
//  SaltScan
//
//  One portion: product, amount and sodium or salt. Shared by Home's "Today"
//  section and the Journal screen.
//

import SwiftUI
import SaltScanCore

struct JournalLineRow: View {
    let line: IntakeLine

    @Environment(\.saltFormatter) private var formatter
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: SSSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(line.displayName.isEmpty ? "journal.line.unknownProduct".localize : line.displayName)
                    .font(SSFont.subheadline().weight(.semibold))
                    .foregroundStyle(Color.ssTextPrimary)
                    .lineLimit(1)
                Text(amountText)
                    .font(SSFont.caption())
                    .foregroundStyle(Color.ssTextSecondary)
            }
            Spacer()
            Text(line.effectiveSodium100g == nil ? "—" : formatter.amount(sodiumGrams: line.sodiumGrams))
                .font(SSFont.subheadline().weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Color.ssPrimary)
        }
        .contentShape(Rectangle())
    }

    /// "1½ × serving (42 g)" when the amount is whole half servings, else "42 g".
    private var amountText: String {
        let mass = PortionInput.formatGrams(line.grams, locale: locale) + " " + "unit.gram".localize
        if let serving = PortionInput.usableServing(line.scan?.servingQuantityGrams),
           let servings = PortionInput.exactServings(grams: line.grams, servingGrams: serving) {
            return String(format: "journal.line.servings".localize, PortionInput.formatServings(servings, locale: locale), mass)
        }
        return mass
    }
}

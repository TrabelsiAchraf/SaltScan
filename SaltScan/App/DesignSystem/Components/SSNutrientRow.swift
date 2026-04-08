//
//  SSNutrientRow.swift
//  SaltScan
//

import SwiftUI

struct SSNutrientRow: View {
    let icon: String
    let label: LocalizedStringKey
    let value: String
    var severity: SSSeverity? = nil

    var body: some View {
        HStack(spacing: SSSpacing.sm) {
            Image(systemName: icon)
                .font(SSFont.title3())
                .frame(width: 32)
                .foregroundStyle(severity?.color ?? .ssPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(SSFont.subheadline())
                    .foregroundStyle(Color.ssTextSecondary)
                Text(value)
                    .font(SSFont.headline())
                    .foregroundStyle(Color.ssTextPrimary)
            }
            Spacer()
            if let severity {
                SSBadge(severity: severity)
            }
        }
        .padding(.vertical, SSSpacing.xs)
    }
}

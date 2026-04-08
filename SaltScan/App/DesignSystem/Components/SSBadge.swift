//
//  SSBadge.swift
//  SaltScan
//
//  Pill badge with icon for severity / status display.
//

import SwiftUI

struct SSBadge: View {
    let title: LocalizedStringKey
    var icon: String? = nil
    var color: Color = .ssPrimary

    var body: some View {
        HStack(spacing: SSSpacing.xxs) {
            if let icon {
                Image(systemName: icon)
            }
            Text(title)
        }
        .font(SSFont.caption().weight(.semibold))
        .foregroundStyle(color)
        .padding(.vertical, SSSpacing.xxs)
        .padding(.horizontal, SSSpacing.xs)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

extension SSBadge {
    init(severity: SSSeverity) {
        self.init(
            title: severity.localizedLabelKey,
            icon: severity.iconName,
            color: severity.color
        )
    }
}

#Preview {
    HStack {
        SSBadge(severity: .low)
        SSBadge(severity: .medium)
        SSBadge(severity: .high)
    }
    .padding()
}

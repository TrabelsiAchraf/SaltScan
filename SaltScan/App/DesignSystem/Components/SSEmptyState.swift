//
//  SSEmptyState.swift
//  SaltScan
//

import SwiftUI

struct SSEmptyState: View {
    let icon: String
    let title: LocalizedStringKey
    var message: LocalizedStringKey? = nil
    var actionTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: SSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 54, weight: .regular))
                .foregroundStyle(Color.ssPrimary.opacity(0.7))
            Text(title)
                .font(SSFont.title3())
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(SSFont.subheadline())
                    .foregroundStyle(Color.ssTextSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                SSButton(title: actionTitle, style: .primary, action: action)
                    .padding(.top, SSSpacing.xs)
                    .frame(maxWidth: 280)
            }
        }
        .padding(SSSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

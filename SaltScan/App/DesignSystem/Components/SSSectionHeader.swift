//
//  SSSectionHeader.swift
//  SaltScan
//

import SwiftUI

struct SSSectionHeader: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    var actionTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(SSFont.title3())
                if let subtitle {
                    Text(subtitle)
                        .font(SSFont.subheadline())
                        .foregroundStyle(Color.ssTextSecondary)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(SSFont.subheadline().weight(.semibold))
                        .foregroundStyle(Color.ssPrimary)
                }
            }
        }
    }
}

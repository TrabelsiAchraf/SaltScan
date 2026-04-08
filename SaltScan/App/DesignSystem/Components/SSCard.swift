//
//  SSCard.swift
//  SaltScan
//
//  Surface container with consistent padding, radius and elevation.
//

import SwiftUI

struct SSCard<Content: View>: View {
    var padding: CGFloat = SSSpacing.md
    var radius: CGFloat = SSRadius.md
    var elevated: Bool = true
    var tint: Color? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint ?? Color.ssSurface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .ssShadow(elevated ? .soft : SSShadow(color: .clear, radius: 0, x: 0, y: 0))
    }
}

#Preview {
    VStack(spacing: SSSpacing.md) {
        SSCard {
            VStack(alignment: .leading) {
                Text("Nutella").font(SSFont.title3())
                Text("15.2g sugar / 100g").font(SSFont.subheadline()).foregroundStyle(Color.ssTextSecondary)
            }
        }
        SSCard(elevated: false, tint: .ssPrimary.opacity(0.12)) {
            Text("Flat tinted card").font(SSFont.body())
        }
    }
    .padding()
}

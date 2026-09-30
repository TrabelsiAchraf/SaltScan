//
//  GoalPresetChips.swift
//  SaltScan
//
//  The reference daily goals for the user's unit (WHO, UK, AHA, FDA), one
//  tap away. Shared by Settings and onboarding; storage stays in grams of salt.
//

import SwiftUI
import SaltScanCore

struct GoalPresetChips: View {
    @Binding var goalGrams: Double
    let unit: SaltUnit

    var body: some View {
        HStack(spacing: SSSpacing.xs) {
            ForEach(GoalPresets.presets(for: unit)) { preset in
                let selected = abs(goalGrams - preset.saltGrams) < 0.01
                Button {
                    goalGrams = preset.saltGrams
                } label: {
                    Text(Self.titleKey(preset.kind))
                        .font(SSFont.caption().weight(.semibold))
                        .padding(.vertical, SSSpacing.xxs)
                        .padding(.horizontal, SSSpacing.xs)
                        .background(selected ? Color.ssPrimary : Color.ssPrimary.opacity(0.12))
                        .foregroundStyle(selected ? Color.white : Color.ssPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    static func titleKey(_ kind: GoalPreset.Kind) -> LocalizedStringKey {
        switch kind {
        case .who: "settings.goal.preset.who"
        case .uk: "settings.goal.preset.uk"
        case .aha: "settings.goal.preset.aha"
        case .whoSodium: "settings.goal.preset.whoSodium"
        case .fda: "settings.goal.preset.fda"
        }
    }
}

//
//  OnboardingView.swift
//  SaltScan
//
//  First launch only: asks why the user watches salt, then proposes a daily
//  goal from that answer (adjustable with the usual presets). The answer is
//  stored on the device only. "Skip" keeps the default 5 g goal.
//

import SwiftUI
import SaltScanCore

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.saltFormatter) private var formatter
    @AppStorage("dailySaltGoalGrams") private var goalGrams: Double = 5.0
    @AppStorage(SaltMotivation.storageKey) private var motivationRaw: String = ""
    @State private var motivation: SaltMotivation?
    @State private var proposedGoal: Double = 5.0
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationStack {
            Group {
                if motivation == nil {
                    motivationStep
                } else {
                    goalStep
                }
            }
            .background(Color.ssGroupedBackground)
            .toolbar {
                if motivation == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("onboarding.skip") { dismiss() }
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation { motivation = nil }
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                        .accessibilityLabel(Text("onboarding.back"))
                    }
                }
            }
        }
        .onAppear { haptic.prepare() }
    }

    // MARK: - Steps

    private var motivationStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SSSpacing.md) {
                Text("onboarding.motivation.title")
                    .font(SSFont.largeTitle())
                Text("onboarding.motivation.subtitle")
                    .font(SSFont.subheadline())
                    .foregroundStyle(Color.ssTextSecondary)
                ForEach(SaltMotivation.allCases) { option in
                    Button { choose(option) } label: {
                        SSCard(padding: SSSpacing.md) {
                            HStack(spacing: SSSpacing.md) {
                                Image(systemName: option.icon)
                                    .font(.title2)
                                    .foregroundStyle(Color.ssPrimary)
                                    .frame(width: 32)
                                Text(option.titleKey)
                                    .font(SSFont.headline())
                                    .foregroundStyle(Color.ssTextPrimary)
                                Spacer()
                                Image(systemName: "chevron.forward")
                                    .foregroundStyle(Color.ssTextTertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(SSSpacing.md)
            .ssReadableWidth()
        }
    }

    private var goalStep: some View {
        VStack(spacing: SSSpacing.lg) {
            Spacer()
            Text("onboarding.goal.title")
                .font(SSFont.title())
                .multilineTextAlignment(.center)
            SSScoreRing(
                progress: 1,
                value: formatter.goal(saltGrams: proposedGoal),
                caption: "onboarding.goal.caption",
                size: 160
            )
            GoalPresetChips(goalGrams: $proposedGoal, unit: formatter.unit)
            Text("onboarding.goal.disclaimer")
                .font(SSFont.caption())
                .foregroundStyle(Color.ssTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            SSButton(title: "onboarding.button.start", icon: "arrow.right.circle.fill") {
                finish()
            }
        }
        .padding(SSSpacing.lg)
        .ssReadableWidth()
    }

    // MARK: - Actions

    private func choose(_ option: SaltMotivation) {
        haptic.impactOccurred()
        proposedGoal = MotivationPresets.goal(
            for: option,
            unit: formatter.unit,
            regionCode: Locale.current.region?.identifier
        ).saltGrams
        withAnimation { motivation = option }
    }

    private func finish() {
        haptic.impactOccurred()
        goalGrams = proposedGoal
        motivationRaw = motivation?.rawValue ?? ""
        dismiss()
    }
}

#Preview {
    OnboardingView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "ar"))
        .environment(\.layoutDirection, .rightToLeft)
}

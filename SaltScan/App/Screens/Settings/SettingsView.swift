//
//  SettingsView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//
import SwiftUI
import SaltScanCore

struct SettingsView: View {
    private let appearances = [Appearance.system, Appearance.dark, Appearance.light]
    @AppStorage("isDarkMode") private var selectedAppearance: Appearance = .system
    @AppStorage("dailySaltGoalGrams") private var goalGrams: Double = 5.0
    @AppStorage(SaltUnitPreference.storageKey) private var unitPreference: SaltUnitPreference = .automatic
    @Environment(\.saltFormatter) private var formatter

    private static let appStoreID = "6740041173"
    private let reviewURL = URL(string: "https://apps.apple.com/app/id\(SettingsView.appStoreID)?action=write-review")!

    /// Marketing version and build read from the bundle, so Settings can never
    /// drift from what App Store Connect shows.
    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                Picker("settings.appearance.title", selection: $selectedAppearance) {
                    ForEach(appearances, id: \.self) {
                        Text($0.text)
                    }
                }
                Picker("settings.unit.title", selection: $unitPreference) {
                    Text("settings.unit.automatic").tag(SaltUnitPreference.automatic)
                    Text("settings.unit.salt").tag(SaltUnitPreference.saltGrams)
                    Text("settings.unit.sodium").tag(SaltUnitPreference.sodiumMilligrams)
                }
                goalRow
            } header: {
                Text("settings.section.general.title")
            } footer: {
                Text(formatter.unit == .sodiumMilligrams ? LocalizedStringKey("settings.goal.footer.sodium") : LocalizedStringKey("settings.goal.footer"))
            }

            Section {
                HStack {
                    Text("settings.section.appVersion.title")
                    Spacer()
                    Text(versionString)
                        .foregroundStyle(Color.ssTextSecondary)
                        .monospacedDigit()
                }

                HStack {
                    Text("settings.section.madeAuthor.title")
                    Button {
                        SocialMediaManager.showAdminTwitterProfile()
                    } label: {
                        Text("settings.section.author.name")
                    }
                }

                Link(destination: reviewURL) {
                    Label("settings.section.rate.title", systemImage: "star.fill")
                }

                NavigationLink("settings.section.termsAndPolicy.title") {
                    TermsAndPrivacyView()
                }
            } header: {
                Text("settings.section.information.title")
            }

            Section {
                HStack {
                    Text("settings.section.source1.title")
                    Spacer()
                    Link("settings.credit.visit.title", destination: URL(string: "https://fr.openfoodfacts.org")!)
                }

                HStack {
                    Text("settings.section.source2.title")
                    Spacer()
                    Link("settings.credit.visit.title", destination: URL(string: "https://undraw.co")!)
                }
            } header: {
                Text("settings.section.credits.title")
            }

            Section {
                NavigationLink("settings.section.FAQ.title") {
                    FAQView()
                }

                NavigationLink("settings.section.contactUs.title") {
                    ContactUsView()
                }
            } header: {
                Text("settings.section.help.title")
            }
        }
    }

    // MARK: - Goal

    /// Slider in the user's unit (grams of salt or milligrams of sodium) with
    /// the usual reference values one tap away. Storage stays in grams of salt.
    private var goalRow: some View {
        let bounds = GoalPresets.sliderRange(for: formatter.unit)
        return VStack(alignment: .leading, spacing: SSSpacing.xs) {
            HStack {
                Text(formatter.unit == .sodiumMilligrams ? LocalizedStringKey("settings.goal.title.sodium") : LocalizedStringKey("settings.goal.title"))
                Spacer()
                Text(formatter.goal(saltGrams: goalGrams))
                    .foregroundStyle(Color.ssPrimary)
                    .monospacedDigit()
            }
            Slider(value: $goalGrams, in: bounds.range, step: bounds.step)
                .tint(Color.ssPrimary)
            HStack(spacing: SSSpacing.xs) {
                ForEach(GoalPresets.presets(for: formatter.unit)) { preset in
                    let selected = abs(goalGrams - preset.saltGrams) < 0.01
                    Button {
                        goalGrams = preset.saltGrams
                    } label: {
                        Text(presetKey(preset.kind))
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
    }

    private func presetKey(_ kind: GoalPreset.Kind) -> LocalizedStringKey {
        switch kind {
        case .who: "settings.goal.preset.who"
        case .uk: "settings.goal.preset.uk"
        case .aha: "settings.goal.preset.aha"
        case .whoSodium: "settings.goal.preset.whoSodium"
        case .fda: "settings.goal.preset.fda"
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
}

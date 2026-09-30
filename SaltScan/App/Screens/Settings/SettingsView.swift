//
//  SettingsView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//
import SwiftUI
import SwiftData
import SaltScanCore

struct SettingsView: View {
    private let appearances = [Appearance.system, Appearance.dark, Appearance.light]
    @AppStorage("isDarkMode") private var selectedAppearance: Appearance = .system
    @AppStorage("dailySaltGoalGrams") private var goalGrams: Double = 5.0
    @AppStorage(SaltUnitPreference.storageKey) private var unitPreference: SaltUnitPreference = .automatic
    @Environment(\.saltFormatter) private var formatter
    @AppStorage(SaltMotivation.storageKey) private var motivationRaw: String = ""
    @AppStorage(HealthSyncService.enabledKey) private var healthEnabled = false
    @AppStorage(HealthSyncService.lastExportCountKey) private var healthLastExportCount = -1
    @ObservedObject private var health = HealthSyncService.shared
    @Environment(\.modelContext) private var context
    @State private var showHealthDenied = false

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
                motivationRow
                goalRow
            } header: {
                Text("settings.section.general.title")
            } footer: {
                Text(formatter.unit == .sodiumMilligrams ? LocalizedStringKey("settings.goal.footer.sodium") : LocalizedStringKey("settings.goal.footer"))
            }

            if health.isAvailable {
                Section {
                    Toggle(isOn: Binding(
                        get: { healthEnabled },
                        set: { newValue in
                            if newValue {
                                Task { await enableHealthExport() }
                            } else {
                                healthEnabled = false
                            }
                        }
                    )) {
                        Label("settings.health.toggle", systemImage: "heart.text.square")
                    }
                    .disabled(health.exportProgress != nil)

                    if let progress = health.exportProgress {
                        ProgressView(value: progress) {
                            Text("settings.health.exporting")
                                .font(SSFont.caption())
                        }
                    }
                } header: {
                    Text("settings.health.title")
                } footer: {
                    VStack(alignment: .leading, spacing: SSSpacing.xxs) {
                        Text("settings.health.footer")
                        if healthEnabled, healthLastExportCount >= 0 {
                            Text(String(format: "settings.health.lastExport".localize, locale: .current, healthLastExportCount))
                        }
                    }
                }
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
        .alert("settings.health.denied.title", isPresented: $showHealthDenied) {
            Button("settings.health.denied.ok", role: .cancel) {}
        } message: {
            Text("settings.health.denied.message")
        }
    }

    // MARK: - Motivation

    /// Changing the reason applies its recommended goal; the slider stays free.
    private var motivationRow: some View {
        Picker("settings.motivation.title", selection: Binding(
            get: { SaltMotivation(rawValue: motivationRaw) },
            set: { newValue in
                motivationRaw = newValue?.rawValue ?? ""
                if let newValue {
                    goalGrams = MotivationPresets.goal(
                        for: newValue,
                        unit: formatter.unit,
                        regionCode: Locale.current.region?.identifier
                    ).saltGrams
                }
            }
        )) {
            Text("settings.motivation.none").tag(SaltMotivation?.none)
            ForEach(SaltMotivation.allCases) { motivation in
                Text(motivation.titleKey).tag(SaltMotivation?.some(motivation))
            }
        }
    }

    // MARK: - Apple Health

    /// Asks for access, then exports the whole journal once. iOS shows the
    /// permission sheet only the first time; later refusals land here directly.
    private func enableHealthExport() async {
        guard await health.requestAuthorization() else {
            healthEnabled = false
            showHealthDenied = true
            return
        }
        healthEnabled = true
        let lines = (try? context.fetch(FetchDescriptor<IntakeLine>())) ?? []
        await health.exportAll(lines.compactMap(\.healthSnapshot))
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
            GoalPresetChips(goalGrams: $goalGrams, unit: formatter.unit)
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

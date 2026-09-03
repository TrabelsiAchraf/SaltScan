//
//  SettingsView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//
import SwiftUI

struct SettingsView: View {
    private let appearances = [Appearance.system, Appearance.dark, Appearance.light]
    @AppStorage("isDarkMode") private var selectedAppearance: Appearance = .system
    @AppStorage("dailySaltGoalGrams") private var goalGrams: Double = 5.0
    @ObservedObject private var adsConsent = AdsConsentManager.shared

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
                VStack(alignment: .leading) {
                    HStack {
                        Text("settings.goal.title")
                        Spacer()
                        Text(String(format: "%.1f g", goalGrams))
                            .foregroundStyle(Color.ssPrimary)
                            .monospacedDigit()
                    }
                    Slider(value: $goalGrams, in: 2...10, step: 0.5)
                        .tint(Color.ssPrimary)
                }
            } header: {
                Text("settings.section.general.title")
            } footer: {
                Text("settings.goal.footer")
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

                if adsConsent.isPrivacyOptionsRequired {
                    Button {
                        adsConsent.presentPrivacyOptions()
                    } label: {
                        Label("settings.section.privacyOptions.title", systemImage: "hand.raised.fill")
                    }
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

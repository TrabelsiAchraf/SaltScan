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
                    Text("settings.appVersion")
                }
                
                HStack {
                    Text("settings.section.madeAuthor.title")
                    Button {
                        SocialMediaManager.showAdminTwitterProfile()
                    } label: {
                        Text("settings.section.author.name")
                    }
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

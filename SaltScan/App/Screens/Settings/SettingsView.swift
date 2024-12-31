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
    
    var body: some View {
        Form {
            Section {
                Picker("settings.appearance.title", selection: $selectedAppearance) {
                    ForEach(appearances, id: \.self) {
                        Text($0.text)
                    }
                }
            } header: {
                Text("settings.section.general.title")
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
                NavigationLink("settings.section.FAQ.title") {
                    EmptyView()
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

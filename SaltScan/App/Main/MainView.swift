//
//  MainView.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
                    }
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                    }
            }
            .navigationTitle("main.title")
        }
    }
}

#Preview {
    MainView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview {
    MainView()
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
}

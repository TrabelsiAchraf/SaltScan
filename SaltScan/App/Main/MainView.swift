//
//  MainView.swift
//  SaltScan
//
//  Root 4-tab container: Home, Scan (modal), History, Settings.
//

import SwiftUI

struct MainView: View {
    @State private var showScanner: Bool = false
    @State private var selectedTab: Tab = .home

    enum Tab: Hashable { case home, history, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView(onScanTapped: { showScanner = true }) }
                .tabItem { Label("main.tab.home", systemImage: "house.fill") }
                .tag(Tab.home)

            // Central "Scan" tab — selecting it opens the camera modal.
            Color.clear
                .tabItem { Label("main.tab.scan", systemImage: "barcode.viewfinder") }
                .tag(Tab.home) // keeps selection on Home after modal closes
                .onAppear { showScanner = true }

            HistoryView()
                .tabItem { Label("main.tab.history", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)

            NavigationStack { SettingsView() }
                .tabItem { Label("main.tab.settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Color.ssPrimary)
        .fullScreenCover(isPresented: $showScanner) {
            ProductScannerView()
        }
    }
}

#Preview {
    MainView()
        .modelContainer(SaltScanModelContainer.shared)
}

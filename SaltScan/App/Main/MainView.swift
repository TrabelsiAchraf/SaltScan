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

    enum Tab: Hashable { case home, scan, history, settings }

    /// Tab binding that intercepts taps on the Scan tab: instead of switching
    /// to it, we present the camera modal and keep the previously-selected
    /// tab active so dismissing the scanner returns the user where they were.
    private var tabBinding: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == .scan {
                    showScanner = true
                } else {
                    selectedTab = newValue
                }
            }
        )
    }

    var body: some View {
        TabView(selection: tabBinding) {
            NavigationStack { HomeView(onScanTapped: { showScanner = true }) }
                .tabItem { Label("main.tab.home", systemImage: "house.fill") }
                .tag(Tab.home)

            // Placeholder — never actually shown because tabBinding intercepts.
            Color.clear
                .tabItem { Label("main.tab.scan", systemImage: "barcode.viewfinder") }
                .tag(Tab.scan)

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

//
//  MainView.swift
//  SaltScan
//
//  Root 4-tab container: Home, Scan (modal), History, Settings.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @State private var showScanner: Bool = false
    @State private var selectedTab: Tab = .home
    @State private var screenshotDetailEntry: ScanEntry?

    enum Tab: Hashable { case home, scan, history, settings }

    @Environment(\.modelContext) private var context

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
#if DEBUG
        .sheet(item: $screenshotDetailEntry) { entry in
            NavigationStack {
                ProductDetailView(barcode: entry.barcode, preloadedEntry: entry)
            }
        }
        .onAppear {
            guard ScreenshotMode.isActive else { return }
            // Defer one runloop tick so the seed in SaltScanApp.init has time
            // to land in the context before we read it.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                applyScreenshotRoute()
            }
        }
#endif
    }

#if DEBUG
    private func applyScreenshotRoute() {
        switch ScreenshotMode.initialRoute {
        case "history":  selectedTab = .history
        case "settings": selectedTab = .settings
        case "scanner":  showScanner = true
        case "detail":
            // Push the rich product detail using the most interesting seeded entry.
            let descriptor = FetchDescriptor<ScanEntry>(
                predicate: #Predicate { $0.barcode == "0123456000002" }
            )
            if let entry = try? context.fetch(descriptor).first {
                screenshotDetailEntry = entry
            }
        default:
            selectedTab = .home
        }
    }
#endif
}

#Preview {
    MainView()
        .modelContainer(SaltScanModelContainer.shared)
}

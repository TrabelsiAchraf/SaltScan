//
//  MainView.swift
//  SaltScan
//
//  Root 4-tab container: Home, Scan (modal), History, Settings.
//

import SwiftUI
import SwiftData
import SaltScanCore

struct MainView: View {
    @AppStorage(SaltUnitPreference.storageKey) private var unitPreference: SaltUnitPreference = .automatic
    @State private var showScanner: Bool = false
    @State private var showStoreFailure = SaltScanModelContainer.didFallBackToMemory
    @State private var showContactFromFailure = false
    @State private var selectedTab: Tab = .home
    @State private var screenshotDetailEntry: ScanEntry?
    @State private var screenshotDetailEntryFullScreen: ScanEntry?
    @State private var screenshotCompareEntries: [ScanEntry] = []
    @State private var showScreenshotCompare = false

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
        .environment(\.saltFormatter, unitPreference.formatter)
        .fullScreenCover(isPresented: $showScanner) {
            ProductScannerView()
        }
        .alert("storeFailure.title", isPresented: $showStoreFailure) {
            Button("storeFailure.contact") { showContactFromFailure = true }
            Button("storeFailure.dismiss", role: .cancel) {}
        } message: {
            Text("storeFailure.message")
        }
        .sheet(isPresented: $showContactFromFailure) {
            NavigationStack { ContactUsView() }
        }
#if DEBUG
        .sheet(item: $screenshotDetailEntry) { entry in
            NavigationStack {
                ProductDetailView(barcode: entry.barcode, preloadedEntry: entry)
            }
        }
        .fullScreenCover(item: $screenshotDetailEntryFullScreen) { entry in
            NavigationStack {
                ProductDetailView(barcode: entry.barcode, preloadedEntry: entry)
            }
        }
        .fullScreenCover(isPresented: $showScreenshotCompare) {
            NavigationStack {
                ComparisonView(entries: screenshotCompareEntries)
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
                // iPad sheets are small centered forms: capture the detail full screen there.
                if UIDevice.current.userInterfaceIdiom == .pad {
                    screenshotDetailEntryFullScreen = entry
                } else {
                    screenshotDetailEntry = entry
                }
            }
        case "compare":
            // Side-by-side of three seeded products with contrasting salt levels.
            selectedTab = .history
            let codes = ScreenshotMode.compareBarcodes
            let descriptor = FetchDescriptor<ScanEntry>(
                predicate: #Predicate { codes.contains($0.barcode) }
            )
            if let entries = try? context.fetch(descriptor), entries.count >= 2 {
                screenshotCompareEntries = entries.sorted {
                    codes.firstIndex(of: $0.barcode) ?? 0 < codes.firstIndex(of: $1.barcode) ?? 0
                }
                showScreenshotCompare = true
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

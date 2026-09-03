//
//  SaltScanApp.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import SwiftUI
import SwiftData

@main
struct SaltScanApp: App {
    @AppStorage("isDarkMode") private var appearance: Appearance = .system
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
#if DEBUG
        // Seed deterministic demo data on launch when running under the
        // marketing-screenshot harness (tools/take_screenshots.sh).
        Task { @MainActor in
            ScreenshotMode.seedIfNeeded(SaltScanModelContainer.shared)
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(appearance.value)
                .onAppear(perform: startAds)
        }
        .modelContainer(SaltScanModelContainer.shared)
    }

    // MARK: - Private

    /// Ads start only after the consent flow has run (no-op outside GDPR
    /// regions). Skipped entirely while capturing marketing screenshots.
    private func startAds() {
#if DEBUG
        if ScreenshotMode.isActive { return }
#endif
        AdsConsentManager.shared.gatherConsentIfNeeded()
    }
}

import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

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
        // Opens (and migrates) the store before the first view reads it, then
        // gives pre-0.5.0 journal lines their identifier and product copy.
        JournalBackfill.run(in: SaltScanModelContainer.shared.mainContext)
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
        }
        .modelContainer(SaltScanModelContainer.shared)
    }
}

import FirebaseCore

/// Firebase is configured only for the Firestore product fallback used by
/// `FirebaseService`. No Analytics, ads or performance monitoring is linked.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

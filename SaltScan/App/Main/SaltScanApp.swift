//
//  SaltScanApp.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct SaltScanApp: App {
    @AppStorage("isDarkMode") private var appearance: Appearance = .system
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        setupAdmob()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(appearance.value)
        }
        .modelContainer(SaltScanModelContainer.shared)
    }
    
    // MARK: - Private
    
    private func setupAdmob() {
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "4812cfe835374af410fe16b30d8b1039" ]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
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

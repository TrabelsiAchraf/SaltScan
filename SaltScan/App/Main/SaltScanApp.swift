//
//  SaltScanApp.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import SwiftUI
import GoogleMobileAds

@main
struct SaltScanApp: App {
    @AppStorage("isDarkMode") private var appearance: Appearance = .system
    
    init() {
        setupAdmob()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(appearance.value)
        }
    }
    
    // MARK: - Private
    
    private func setupAdmob() {
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "4812cfe835374af410fe16b30d8b1039" ]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}

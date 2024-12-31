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
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(appearance.value)
        }
    }
    
    // MARK: - Private
    
    private func setupAdmob() {
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "89049032007008882600122441581485" ]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
}

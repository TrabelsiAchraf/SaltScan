//
//  SaltScanApp.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 29/12/2024.
//

import SwiftUI

@main
struct SaltScanApp: App {
    @AppStorage("isDarkMode") private var appearance: Appearance = .system
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(appearance.value)
        }
    }
}

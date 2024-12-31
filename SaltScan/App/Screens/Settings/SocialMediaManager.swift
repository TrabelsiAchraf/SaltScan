//
//  SocialMediaManager.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//

import SwiftUI

struct SocialMediaManager {
    static func showAdminTwitterProfile() {
        let twitterName = "twitter"
        let twitterDomain = "com"
        let adminUserName = "Tr_Achraf"
        
        let application = UIApplication.shared
        if let appURL = URL(string: "\(twitterName)://user? screen_name=\(adminUserName)"),
           application.canOpenURL(appURL) {
            application.open(appURL)
        } else if let webURL = URL(string: "https://\(twitterName).\(twitterDomain)/\(adminUserName)") {
            application.open(webURL)
        }
    }
}

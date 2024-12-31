//
//  Appearance.swift
//  SaltScan
//
//  Created by Achraf Trabelsi on 30/12/2024.
//

import SwiftUI

enum Appearance: String {
    case system, light, dark
    var value: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    var text: String {
        switch self {
        case .system:
            return "app.appearance.automatic".localize
        case .light:
            return "app.appearance.light".localize
        case .dark:
            return "app.appearance.dark".localize
        }
    }
}

//
//  SaltMotivation+UI.swift
//  SaltScan
//

import SwiftUI
import SaltScanCore

extension SaltMotivation {
    /// `@AppStorage` key; the answer never leaves the device.
    static let storageKey = "saltMotivation"

    var titleKey: LocalizedStringKey {
        switch self {
        case .bloodPressure: "motivation.bloodPressure"
        case .heart: "motivation.heart"
        case .kidneys: "motivation.kidneys"
        case .pregnancy: "motivation.pregnancy"
        case .healthierEating: "motivation.healthierEating"
        }
    }

    var icon: String {
        switch self {
        case .bloodPressure: "waveform.path.ecg"
        case .heart: "heart.fill"
        case .kidneys: "drop.fill"
        case .pregnancy: "figure.and.child.holdinghands"
        case .healthierEating: "leaf.fill"
        }
    }
}

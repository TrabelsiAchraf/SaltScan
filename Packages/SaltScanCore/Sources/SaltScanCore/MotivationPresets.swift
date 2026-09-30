//
//  MotivationPresets.swift
//  SaltScanCore
//
//  Onboarding asks why the user watches salt; the answer picks a starting
//  daily goal among the existing presets. Guidelines, not medical advice.
//

import Foundation

public enum SaltMotivation: String, Sendable, CaseIterable, Identifiable {
    case bloodPressure
    case heart
    case kidneys
    case pregnancy
    case healthierEating

    public var id: String { rawValue }
}

public enum MotivationPresets {
    /// Regions that follow the UK 6 g reference.
    public static let ukRegions: Set<String> = ["GB", "IE"]

    public static func goal(for motivation: SaltMotivation, unit: SaltUnit, regionCode: String?) -> GoalPreset {
        switch (unit, motivation) {
        case (.sodiumMilligrams, .bloodPressure), (.sodiumMilligrams, .heart):
            return GoalPresets.preset(.aha)
        case (.sodiumMilligrams, .kidneys):
            return GoalPresets.preset(.whoSodium)
        case (.sodiumMilligrams, .pregnancy), (.sodiumMilligrams, .healthierEating):
            return GoalPresets.preset(.fda)
        case (.saltGrams, .pregnancy), (.saltGrams, .healthierEating):
            let isUK = ukRegions.contains(regionCode?.uppercased() ?? "")
            return GoalPresets.preset(isUK ? .uk : .who)
        case (.saltGrams, _):
            return GoalPresets.preset(.who)
        }
    }
}

//
//  SaltFormatterEnvironment.swift
//  SaltScan
//
//  One `SaltFormatter` for the whole view tree, derived from the unit
//  preference in Settings and the device region. `MainView` injects it so a
//  change in Settings re-renders every screen that shows a quantity.
//

import SwiftUI
import SaltScanCore

private struct SaltFormatterKey: EnvironmentKey {
    static let defaultValue = SaltUnitPreference.automatic.formatter
}

extension EnvironmentValues {
    var saltFormatter: SaltFormatter {
        get { self[SaltFormatterKey.self] }
        set { self[SaltFormatterKey.self] = newValue }
    }
}

extension SaltUnitPreference {
    /// `@AppStorage` key shared by Settings and MainView.
    static let storageKey = "saltUnitPreference"

    var formatter: SaltFormatter {
        SaltFormatter(
            unit: resolved(regionCode: Locale.current.region?.identifier),
            gramSymbol: "unit.gram".localize,
            milligramSymbol: "unit.milligram".localize
        )
    }
}

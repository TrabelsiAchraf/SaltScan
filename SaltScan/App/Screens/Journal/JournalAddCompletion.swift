//
//  JournalAddCompletion.swift
//  SaltScan
//
//  Lets the product picker close itself once a portion was added from the
//  scanner or Open Food Facts search it presents.
//

import SwiftUI

private struct JournalAddCompletionKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    /// Called after a portion was added from a product sheet; nil outside the picker.
    var journalAddCompletion: (() -> Void)? {
        get { self[JournalAddCompletionKey.self] }
        set { self[JournalAddCompletionKey.self] = newValue }
    }
}

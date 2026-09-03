//
//  ReviewGate.swift
//  SaltScan
//
//  Decides when to ask for an App Store rating. Apple throttles the system
//  prompt to three per year, so we only ask at a positive moment (third
//  successful scan or first journal entry), once per marketing version and at
//  most every 90 days. Never fires while the screenshot harness runs.
//

import Foundation

enum ReviewGate {
    private static let scansKey = "review.successfulScans"
    private static let journalKey = "review.journalAdds"
    private static let askedVersionKey = "review.askedForVersion"
    private static let lastAskedKey = "review.lastAskedAt"
    private static let cooldown: TimeInterval = 90 * 24 * 3600

    private static var defaults: UserDefaults { .standard }

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    static func recordSuccessfulScan() {
        defaults.set(defaults.integer(forKey: scansKey) + 1, forKey: scansKey)
    }

    static func recordJournalAdd() {
        defaults.set(defaults.integer(forKey: journalKey) + 1, forKey: journalKey)
    }

    /// True when the user reached a positive moment and we have not asked for
    /// this version yet, nor within the cooldown window.
    static var shouldAsk: Bool {
        guard defaults.string(forKey: askedVersionKey) != currentVersion else { return false }
        if let last = defaults.object(forKey: lastAskedKey) as? Date,
           Date().timeIntervalSince(last) < cooldown {
            return false
        }
        let scans = defaults.integer(forKey: scansKey)
        let adds = defaults.integer(forKey: journalKey)
        return scans >= 3 || adds >= 1
    }

    static func markAsked() {
        defaults.set(currentVersion, forKey: askedVersionKey)
        defaults.set(Date(), forKey: lastAskedKey)
    }
}

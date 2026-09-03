//
//  ScreenshotMode.swift
//  SaltScan
//
//  Debug-only helpers used by `tools/take_screenshots.sh` to drive the
//  marketing screenshot pipeline. The launch argument `-screenshotMode YES`
//  flips this on; `-screenshotInitialRoute X` chooses which screen to start
//  on. Real users never hit this code path because:
//    - the file is wrapped in `#if DEBUG`
//    - `isActive` reads ProcessInfo, not UserDefaults persistence
//

#if DEBUG
import Foundation
import SwiftData

enum ScreenshotMode {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotMode") &&
            ProcessInfo.processInfo.arguments.contains("YES")
    }

    /// Barcodes of the seeded products used by the "compare" route, in display order.
    static let compareBarcodes = ["0123456000004", "0123456000002", "0123456000003"]

    /// Where to navigate after launch: "home" | "history" | "detail" | "scanner" | "settings" | "compare".
    static var initialRoute: String {
        if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-screenshotInitialRoute"),
           i + 1 < ProcessInfo.processInfo.arguments.count {
            return ProcessInfo.processInfo.arguments[i + 1]
        }
        return "home"
    }

    /// Insert a deterministic, demo-friendly catalogue of products + a partly
    /// filled daily intake so every screenshot has rich content.
    @MainActor
    static func seedIfNeeded(_ container: ModelContainer) {
        guard isActive else { return }
        let context = container.mainContext

        // Wipe any prior state so reruns are deterministic.
        try? context.delete(model: IntakeLine.self)
        try? context.delete(model: DailyIntake.self)
        try? context.delete(model: ScanEntry.self)

        let now = Date()
        let cal = Calendar.current
        let entries: [(String, String, String, Double, String, Double, Double, Double, Double, Bool)] = [
            // barcode, name, brand, sodium100g, nutriscore, energy, sugars, satFat, proteins, fav
            ("0123456000001", "San Pellegrino",  "Sparkling water", 0.008, "a", 0,   0.0,  0.0,  0.0, true),
            ("0123456000002", "Doritos Nacho",   "Frito-Lay",       0.568, "d", 498, 1.4,  3.2,  6.8, false),
            ("0123456000003", "Soy Sauce",       "Kikkoman",        2.323, "e", 73,  3.0,  0.0,  10.5, false),
            ("0123456000004", "Whole Milk",      "Lactel",          0.040, "b", 64,  4.7,  2.3,  3.2, true),
            ("0123456000005", "Camembert",       "Président",       0.728, "d", 297, 0.5,  15.0, 19.8, false),
        ]
        var scans: [ScanEntry] = []
        for (i, (bc, name, brand, sodium, grade, energy, sugars, satFat, proteins, fav)) in entries.enumerated() {
            let entry = ScanEntry(
                barcode: bc,
                productName: name,
                brand: brand,
                imageURL: nil,
                sodium100g: sodium,
                energyKcal100g: energy,
                sugars100g: sugars,
                saturatedFat100g: satFat,
                proteins100g: proteins,
                nutriscoreGrade: grade,
                ingredientsText: nil,
                allergens: ["milk", "soy"],
                additives: ["E330", "E621"],
                scannedAt: cal.date(byAdding: .minute, value: -i * 27, to: now) ?? now,
                isFavorite: fav
            )
            context.insert(entry)
            scans.append(entry)
        }

        // Build today's intake bucket — about 60% of the 5g goal so the ring
        // shows clear progress without looking alarming.
        let bucket = DailyIntake(day: now)
        context.insert(bucket)
        for (scan, grams) in zip(scans.prefix(3), [60.0, 30.0, 18.0]) {
            let line = IntakeLine(scan: scan, grams: grams)
            context.insert(line)
            line.intake = bucket
        }

        try? context.save()
    }
}
#endif

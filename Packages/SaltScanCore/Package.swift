// swift-tools-version: 6.0
import PackageDescription

// Pure, UI-free logic shared by the app: unit conversion and formatting,
// plausibility checks on Open Food Facts data, serving information.
// Kept in a package so it can be tested with `swift test` without a simulator.
let package = Package(
    name: "SaltScanCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "SaltScanCore", targets: ["SaltScanCore"]),
    ],
    targets: [
        .target(name: "SaltScanCore"),
        .testTarget(name: "SaltScanCoreTests", dependencies: ["SaltScanCore"]),
    ]
)

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

SaltScan is a native iOS app (SwiftUI) that scans food product barcodes and surfaces salt/nutrition information. Built with Xcode; dependencies managed via Xcode project (Swift packages: Firebase Core + Firestore only; no ads, no analytics).

## Build / Run

Open `SaltScan.xcodeproj` in Xcode and run the `SaltScan` scheme on a simulator or device. No separate lint/test targets are configured in-repo.

Command-line build:
```
xcodebuild -project SaltScan.xcodeproj -scheme SaltScan -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Architecture

MVVM with SwiftUI. Source lives under `SaltScan/App/`:

- `Main/` — `SaltScanApp` (entry point, configures Firebase via `AppDelegate`) and `MainView` (root tab container).
- `Screens/` — feature folders, each containing a `View` + `ViewModel` (+ model types). Features: `Onboarding`, `Home` (with `Articles`), `Scanner` (barcode capture), `Result` (product details), `Settings`.
- `Services/APIService.swift` — singleton `APIService` fetches products from OpenFoodFacts (`world.openfoodfacts.org/api/v0/product/{barcode}.json`). On network/decoding failure it falls back to `FirebaseService`, which reads from the Firestore `products` collection and maps `FirebaseProductResponse` → `ProductResponse` via `mapToProductResponse()`.
- `Components/` — reusable SwiftUI views (e.g. `PrimaryButton`).
- `Utils/` — `Constants`, `Appearance` (light/dark/system via `@AppStorage("isDarkMode")`), `ColorsManager`, `ReviewGate` (rating prompt gating), misc helpers.

`Configuration/` holds `Info.plist`, `GoogleService-Info.plist`, `Assets.xcassets`, and `Localizable.xcstrings` (multi-language including Arabic — RTL support matters when touching layout).

## Conventions

- Services are singletons (`APIService.shared`, `FirebaseService.shared`) with `private init()`.
- Async network calls use Swift Concurrency (`async throws`).
- Version bumps are tracked via `chore: migrate app version to X.Y.Z` commits.

#!/usr/bin/env bash
#
# Capture marketing screenshots of SaltScan from the iOS Simulator.
#
# Drives 5 screens × 4 store locales = 20 raw captures on an iPhone 16 Pro Max
# (6.9", 1320 × 2868), then tools/composite_screenshots.py turns them into the
# App Store slides for every locale and display size.
#
# Requires: iPhone 16 Pro Max booted, Debug app installed (com.tadev.SaltScan):
#   xcodebuild -project SaltScan.xcodeproj -scheme SaltScan -configuration Debug \
#     -destination "platform=iOS Simulator,id=$SIM_UUID" -derivedDataPath build build
#   xcrun simctl install "$SIM_UUID" build/Build/Products/Debug-iphonesimulator/SaltScan.app
#
set -euo pipefail

SIM_UUID="${SIM_UUID:-B8161024-9E45-4E9C-A2BE-43A71001BB82}"   # iPhone 16 Pro Max
BUNDLE_ID="com.tadev.SaltScan"
RAW_DIR="$PWD/marketing/raw"
mkdir -p "$RAW_DIR"

# (route, slide number) — order matches tools/composite_screenshots.py.
ROUTES=(
  "home:1"
  "scanner:2"
  "detail:3"
  "compare:4"
  "history:5"
)

# Store locales. The region matters: en-US shows sodium in milligrams,
# en-GB grams of salt, so the two English sets are captured separately.
LOCALES=(en-US en-GB fr-FR ar-SA)

for locale in "${LOCALES[@]}"; do
  lang="${locale%%-*}"
  apple_locale="${locale/-/_}"
  mkdir -p "$RAW_DIR/$locale"
  rm -f "$RAW_DIR/$locale"/*.png
  for entry in "${ROUTES[@]}"; do
    route="${entry%%:*}"
    slug="${entry##*:}"
    echo "==> $locale / $route"

    # Terminate any prior instance.
    xcrun simctl terminate "$SIM_UUID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    sleep 0.4

    # Launch with our screenshot harness arguments.
    xcrun simctl launch "$SIM_UUID" "$BUNDLE_ID" \
      -screenshotMode YES \
      -screenshotInitialRoute "$route" \
      -AppleLanguages "($locale)" \
      -AppleLocale "$apple_locale" >/dev/null

    # Give SwiftUI time to render the requested route (modals animate in).
    sleep 2.8

    out="$RAW_DIR/$locale/${slug}_${route}.png"
    xcrun simctl io "$SIM_UUID" screenshot "$out"
    echo "    wrote $out"
  done
done

echo "All raw captures done. Run: python3 tools/composite_screenshots.py"

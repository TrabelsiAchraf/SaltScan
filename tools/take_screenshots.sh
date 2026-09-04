#!/usr/bin/env bash
#
# Capture marketing screenshots of SaltScan from the iOS Simulator.
#
# Drives 5 screens × 4 store locales = 20 raw captures per device (iPhone 16 Pro
# Max 1320 × 2868, or iPad Pro 13-inch 2064 × 2752 with DEVICE=ipad), then
# tools/composite_screenshots.py turns them into the App Store slides.
#
# Requires: iPhone 16 Pro Max booted, Debug app installed (com.tadev.SaltScan):
#   xcodebuild -project SaltScan.xcodeproj -scheme SaltScan -configuration Debug \
#     -destination "platform=iOS Simulator,id=$SIM_UUID" -derivedDataPath build build
#   xcrun simctl install "$SIM_UUID" build/Build/Products/Debug-iphonesimulator/SaltScan.app
#
set -euo pipefail

# DEVICE=iphone (default) captures on the iPhone 16 Pro Max (6.9"),
# DEVICE=ipad on the iPad Pro 13-inch (M4). Override SIM_UUID to pick another simulator.
DEVICE="${DEVICE:-iphone}"
if [[ "$DEVICE" == "ipad" ]]; then
  DEFAULT_SIM="8B4F0276-6A5A-4372-B838-8AEE063D22C5"   # iPad Pro 13-inch (M4), iOS 18
else
  DEFAULT_SIM="B8161024-9E45-4E9C-A2BE-43A71001BB82"   # iPhone 16 Pro Max, iOS 18
fi
SIM_UUID="${SIM_UUID:-$DEFAULT_SIM}"
BUNDLE_ID="com.tadev.SaltScan"
RAW_DIR="$PWD/marketing/raw/$DEVICE"
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

echo "All $DEVICE captures done. Run: python3 tools/composite_screenshots.py"

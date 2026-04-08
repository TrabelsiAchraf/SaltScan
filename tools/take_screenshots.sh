#!/usr/bin/env bash
#
# Capture marketing screenshots of SaltScan from the iOS Simulator.
#
# Drives 5 screens × 3 languages = 15 raw captures, then composites them
# into the marketing slide template via tools/generate_screenshots.py.
#
# Requires: iPhone 16 Pro Max booted, app installed at com.tadev.SaltScan.
#
set -euo pipefail

SIM_UUID="B8161024-9E45-4E9C-A2BE-43A71001BB82"   # iPhone 16 Pro Max
BUNDLE_ID="com.tadev.SaltScan"
RAW_DIR="$PWD/marketing/raw"
mkdir -p "$RAW_DIR"

# (route, slug)
ROUTES=(
  "home:1"
  "history:4"
  "detail:3"
  "scanner:1bis"
  "settings:5"
)

LANGS=(en fr ar)

for lang in "${LANGS[@]}"; do
  mkdir -p "$RAW_DIR/$lang"
  for entry in "${ROUTES[@]}"; do
    route="${entry%%:*}"
    slug="${entry##*:}"
    echo "==> $lang / $route"

    # Terminate any prior instance.
    xcrun simctl terminate "$SIM_UUID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    sleep 0.4

    # Launch with our screenshot harness arguments.
    xcrun simctl launch "$SIM_UUID" "$BUNDLE_ID" \
      -screenshotMode YES \
      -screenshotInitialRoute "$route" \
      -AppleLanguages "($lang)" \
      -AppleLocale "$lang" >/dev/null

    # Give SwiftUI time to render the requested route.
    sleep 2.2

    out="$RAW_DIR/$lang/${slug}_${route}.png"
    xcrun simctl io "$SIM_UUID" screenshot "$out"
    echo "    wrote $out"
  done
done

echo "All raw captures done. Run: python3 tools/composite_screenshots.py"

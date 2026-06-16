#!/bin/bash
# ------------------------------------------------------------
# TinyMind – Build and package macOS release
# ------------------------------------------------------------
# This script performs the following steps:
#   1️⃣ Build the Flutter macOS app in release mode.
#   2️⃣ Package the resulting .app bundle as a .zip archive.
#   3️⃣ Create a compressed .dmg image for easy distribution.
#
# Prerequisites:
#   - Flutter SDK installed and added to PATH.
#   - macOS command‑line tools (hdiutil, zip) are available (default on macOS).
#   - Run this script from the repository root.
#
# Usage:
#   chmod +x scripts/build_release.sh   # make it executable (once)
#   ./scripts/build_release.sh
# ------------------------------------------------------------

set -euo pipefail

# 1️⃣ Build the app
echo "🔧 Building TinyMind macOS app (release)..."
flutter build macos --release

# Define paths
APP_PATH="build/macos/Build/Products/Release/TinyMind.app"
ZIP_NAME="TinyMind-macOS.zip"
DMG_NAME="TinyMind-macOS.dmg"

if [ ! -d "$APP_PATH" ]; then
  echo "❌ Error: .app bundle not found at $APP_PATH"
  exit 1
fi

# 2️⃣ Create ZIP archive
echo "📦 Creating ZIP archive $ZIP_NAME..."
rm -f "$ZIP_NAME"
zip -r "$ZIP_NAME" "$APP_PATH" >/dev/null

# 3️⃣ Create DMG image
#   -volname sets the displayed volume name when the dmg is opened.
#   -format UDZO creates a compressed (zlib) dmg.
#   -ov overwrites any existing file.

echo "🖼️ Creating DMG $DMG_NAME..."
rm -f "$DMG_NAME"
hdiutil create -volname "TinyMind" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_NAME"

echo "✅ Build and packaging complete!"
echo "   • $ZIP_NAME"
echo "   • $DMG_NAME"

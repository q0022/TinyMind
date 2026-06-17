#!/bin/bash
# ------------------------------------------------------------
# TinyMind – Build, Sign, Notarize and Package macOS release
# ------------------------------------------------------------
# This script performs the following steps:
#   1️⃣ Build the Flutter macOS app in release mode.
#   2️⃣ Codesign the .app bundle using Developer ID Application.
#   3️⃣ Submit the bundle for Apple Notarization and wait for success.
#   4️⃣ Staple the Notarization ticket onto the .app bundle.
#   5️⃣ Package the final stapled app as .zip and .dmg.
#   6️⃣ Sign the ZIP archive for Sparkle (auto_updater) updates.
# ------------------------------------------------------------

set -euo pipefail

# 1️⃣ Build the app
echo "🔧 Building TinyMind macOS app (release)..."
# ลบ Llama.framework ของเก่าออกก่อน (ป้องกันปัญหา shallow bundle validation ของ Xcode)
rm -rf "build/macos/Build/Products/Release/TinyMind.app/Contents/Frameworks/Llama.framework"
rm -rf "build/macos/Build/Products/Release/tinymind.app/Contents/Frameworks/Llama.framework"
flutter build macos --release

# Define paths
APP_PATH="build/macos/Build/Products/Release/TinyMind.app"
ZIP_NAME="TinyMind-macOS.zip"
DMG_NAME="TinyMind-macOS.dmg"

# เปลี่ยนชื่อจาก tinymind.app เป็น TinyMind.app ให้ถูกต้องตามเคสตัวพิมพ์ใหญ่-เล็กของระบบ macOS
if [ -d "build/macos/Build/Products/Release/tinymind.app" ]; then
  echo "🔄 Renaming tinymind.app to TinyMind.app..."
  mv "build/macos/Build/Products/Release/tinymind.app" "build/macos/Build/Products/Release/TinyMind_temp.app"
  mv "build/macos/Build/Products/Release/TinyMind_temp.app" "$APP_PATH"
fi

if [ ! -d "$APP_PATH" ]; then
  echo "❌ Error: .app bundle not found at $APP_PATH"
  exit 1
fi

# 1.5 Copy Llama.framework from pub cache to the app bundle Frameworks folder
echo "📦 Copying Llama.framework from pub cache to app bundle..."
mkdir -p "$APP_PATH/Contents/Frameworks"
rm -rf "$APP_PATH/Contents/Frameworks/Llama.framework"
cp -R "$HOME/.pub-cache/hosted/pub.dev/llama_cpp_dart-0.2.2/dist/Llama.xcframework/macos-arm64/Llama.framework" "$APP_PATH/Contents/Frameworks/"

# 1.6 Unpack, codesign and repack LaunchAtLogin helper zip files in resources
echo "🛡️ Unpacking, codesigning, and repacking LaunchAtLogin helper zip files..."
BUNDLE_RESOURCES="$(pwd)/$APP_PATH/Contents/Resources/LaunchAtLogin_LaunchAtLogin.bundle/Contents/Resources"

if [ -d "$BUNDLE_RESOURCES" ]; then
  TEMP_DIR=$(mktemp -d)
  
  # 1. Process LaunchAtLoginHelper.zip
  if [ -f "$BUNDLE_RESOURCES/LaunchAtLoginHelper.zip" ]; then
    echo "  Processing LaunchAtLoginHelper.zip..."
    unzip -q "$BUNDLE_RESOURCES/LaunchAtLoginHelper.zip" -d "$TEMP_DIR/no-runtime"
    
    # Sign nested binary
    codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$TEMP_DIR/no-runtime/LaunchAtLoginHelper.app/Contents/MacOS/LaunchAtLoginHelper"
    # Sign app bundle
    codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$TEMP_DIR/no-runtime/LaunchAtLoginHelper.app"
    
    # Pack it back
    rm -f "$BUNDLE_RESOURCES/LaunchAtLoginHelper.zip"
    (cd "$TEMP_DIR/no-runtime" && zip -r -q "$BUNDLE_RESOURCES/LaunchAtLoginHelper.zip" LaunchAtLoginHelper.app)
  fi

  # 2. Process LaunchAtLoginHelper-with-runtime.zip
  if [ -f "$BUNDLE_RESOURCES/LaunchAtLoginHelper-with-runtime.zip" ]; then
    echo "  Processing LaunchAtLoginHelper-with-runtime.zip..."
    unzip -q "$BUNDLE_RESOURCES/LaunchAtLoginHelper-with-runtime.zip" -d "$TEMP_DIR/with-runtime"
    
    # Sign nested dylibs (bottom-up)
    find "$TEMP_DIR/with-runtime/LaunchAtLoginHelper.app/Contents/Frameworks" -type f -name "*.dylib" | while read -r dylib; do
      echo "    Signing helper dylib: $(basename "$dylib")"
      codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$dylib"
    done
    
    # Sign nested binary
    codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$TEMP_DIR/with-runtime/LaunchAtLoginHelper.app/Contents/MacOS/LaunchAtLoginHelper"
    
    # Sign app bundle
    codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$TEMP_DIR/with-runtime/LaunchAtLoginHelper.app"
    
    # Pack it back
    rm -f "$BUNDLE_RESOURCES/LaunchAtLoginHelper-with-runtime.zip"
    (cd "$TEMP_DIR/with-runtime" && zip -r -q "$BUNDLE_RESOURCES/LaunchAtLoginHelper-with-runtime.zip" LaunchAtLoginHelper.app)
  fi
  
  # Clean up temp dir
  rm -rf "$TEMP_DIR"
fi


# 2️⃣ Codesign all sub-components with Hardened Runtime (bottom-up order)
echo "🛡️ Codesigning nested Mach-O binaries..."
find "$APP_PATH/Contents/Frameworks" -type f | while read -r file; do
  if [ ! -L "$file" ] && file "$file" | grep -q "Mach-O"; then
    echo "  Signing Mach-O: $file"
    codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$file"
  fi
done

echo "🛡️ Codesigning nested XPC services and helper apps..."
find "$APP_PATH/Contents/Frameworks" -name "*.xpc" -type d | while read -r xpc; do
  echo "  Signing XPC: $xpc"
  codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$xpc"
done
find "$APP_PATH/Contents/Frameworks" -name "*.app" -type d | while read -r sub_app; do
  echo "  Signing Sub-App: $sub_app"
  codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$sub_app"
done

echo "🛡️ Codesigning nested frameworks..."
find "$APP_PATH/Contents/Frameworks" -name "*.framework" -type d | while read -r fw; do
  echo "  Signing Framework: $fw"
  codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$fw"
done

echo "🛡️ Codesigning main executable..."
codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$APP_PATH/Contents/MacOS/tinymind"

echo "🛡️ Codesigning main TinyMind.app bundle..."
codesign --force --options runtime --timestamp --sign "Developer ID Application: CSN ADVANCE COMPANY LIMITED (8DY6N2T2V8)" "$APP_PATH"

# 3️⃣ Notarize the app bundle
NOTARY_ZIP="TinyMind-notarize.zip"
echo "📦 Creating temporary ZIP for notarization..."
rm -f "$NOTARY_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARY_ZIP"

echo "🚀 Submitting to Apple Notarization Service (this might take a minute)..."
# We use the keychain profile "TinyMindNotaryProfile" stored on P'Boy's Mac
xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "TinyMindNotaryProfile" --wait

echo "🧹 Cleaning up temporary notarize ZIP..."
rm -f "$NOTARY_ZIP"

# 4️⃣ Staple the Notarization ticket
echo "📎 Stapling Notarization ticket to TinyMind.app..."
xcrun stapler staple "$APP_PATH"

# Verify signature and notarization status
echo "🔍 Verifying code signature and notarization..."
codesign -vvv --deep --strict "$APP_PATH"
spctl --assess --verbose --type execute "$APP_PATH"

# 5️⃣ Create distribution ZIP archive
echo "📦 Creating final ZIP archive $ZIP_NAME..."
rm -f "$ZIP_NAME"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_NAME"

# Create distribution DMG image
echo "🖼️ Creating final DMG $DMG_NAME..."
rm -f "$DMG_NAME"
hdiutil create -volname "TinyMind" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_NAME"

# 6️⃣ Generate Sparkle update signature
echo "🔑 Generating Sparkle update signature for $ZIP_NAME..."
dart run auto_updater:sign_update "$ZIP_NAME"

echo "✅ Build, Signing, Notarization, and Packaging complete!"
echo "   • $ZIP_NAME"
echo "   • $DMG_NAME"

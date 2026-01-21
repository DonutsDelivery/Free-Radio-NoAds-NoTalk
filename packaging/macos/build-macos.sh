#!/bin/bash
# Build macOS app bundle for Free Radio
# Requirements: Qt6, CMake, macdeployqt

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build-macos"

echo "Building Free Radio for macOS..."
echo "Project directory: $PROJECT_DIR"

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure and build
cmake "$PROJECT_DIR/freeradio" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.15

make -j$(sysctl -n hw.ncpu)

# Create app bundle structure
APP_BUNDLE="Free Radio.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp freeradio "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "$SCRIPT_DIR/Info.plist" "$APP_BUNDLE/Contents/"

# Copy icon (convert SVG to icns if needed)
if [ -f "$PROJECT_DIR/freeradio/icons/freeradio.icns" ]; then
    cp "$PROJECT_DIR/freeradio/icons/freeradio.icns" "$APP_BUNDLE/Contents/Resources/"
else
    # Create a placeholder - in production, use a real icns file
    echo "Warning: No .icns icon found. Using system icon."
fi

# Deploy Qt libraries
macdeployqt "$APP_BUNDLE" -qmldir="$PROJECT_DIR/freeradio/contents/ui" -verbose=1

# Create DMG
hdiutil create -volname "Free Radio" -srcfolder "$APP_BUNDLE" -ov -format UDZO "FreeRadio-2.0.0-macOS.dmg"

echo "macOS build complete!"
ls -la *.dmg

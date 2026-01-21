#!/bin/bash
# Build AppImage for Free Radio
# Requirements: linuxdeploy, linuxdeploy-plugin-qt

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build-appimage"
APPDIR="$BUILD_DIR/AppDir"

echo "Building Free Radio AppImage..."
echo "Project directory: $PROJECT_DIR"

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure and build
cmake "$PROJECT_DIR/freeradio" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr

make -j$(nproc)

# Create AppDir structure
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/scalable/apps"

# Copy files
cp freeradio "$APPDIR/usr/bin/"
cp "$PROJECT_DIR/freeradio/freeradio.desktop" "$APPDIR/usr/share/applications/"
cp "$PROJECT_DIR/freeradio/icons/freeradio.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/"

# Download linuxdeploy if not present
if [ ! -f linuxdeploy-x86_64.AppImage ]; then
    wget -c "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
    chmod +x linuxdeploy-x86_64.AppImage
fi

if [ ! -f linuxdeploy-plugin-qt-x86_64.AppImage ]; then
    wget -c "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage"
    chmod +x linuxdeploy-plugin-qt-x86_64.AppImage
fi

# Build AppImage
export QMAKE=$(which qmake6 || which qmake)
./linuxdeploy-x86_64.AppImage --appdir "$APPDIR" \
    --desktop-file "$APPDIR/usr/share/applications/freeradio.desktop" \
    --icon-file "$APPDIR/usr/share/icons/hicolor/scalable/apps/freeradio.svg" \
    --plugin qt \
    --output appimage

echo "AppImage created successfully!"
ls -la *.AppImage

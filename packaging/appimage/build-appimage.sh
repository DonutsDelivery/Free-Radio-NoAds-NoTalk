#!/bin/bash
# Build the DonutRadio AppImage
# Requirements: cmake, a C++ toolchain, Qt 6, KF6 Kirigami, libpulse, wget
# (linuxdeploy and linuxdeploy-plugin-qt are downloaded when missing)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build-appimage"
APPDIR="$BUILD_DIR/AppDir"
APP_ID="online.donutsdelivery.DonutRadio"
SRC_DIR="$PROJECT_DIR/freeradio"

echo "Building DonutRadio AppImage..."
echo "Project directory: $PROJECT_DIR"

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure and build. The Plasma widget stays out of the AppImage.
cmake -S "$SRC_DIR" -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DDONUTRADIO_INSTALL_PLASMOID=OFF

cmake --build build -j"$(nproc)"

# Stage with cmake --install. This is the only step that copies every target
# (binary, QML audio plugin, desktop file, metainfo, icons) into the AppDir.
DESTDIR="$APPDIR" cmake --install build

# Download linuxdeploy if not present
if [ ! -f linuxdeploy-x86_64.AppImage ]; then
    wget -c "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
    chmod +x linuxdeploy-x86_64.AppImage
fi

if [ ! -f linuxdeploy-plugin-qt-x86_64.AppImage ]; then
    wget -c "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage"
    chmod +x linuxdeploy-plugin-qt-x86_64.AppImage
fi

# Bundle Qt and the libraries the installed plugin needs. The AppDir QML tree is
# added so the plugin installed above is scanned along with the system modules.
export QMAKE=$(which qmake6 || which qmake)
export QML_SOURCES_PATHS="$SRC_DIR/contents/ui"
export QML_MODULES_PATHS="${QML_MODULES_PATHS:+$QML_MODULES_PATHS:}$APPDIR/usr/lib/qt6/qml"
export LD_LIBRARY_PATH="$APPDIR/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export EXTRA_QT_PLUGINS="multimedia"

./linuxdeploy-x86_64.AppImage --appdir "$APPDIR" \
    --desktop-file "$SRC_DIR/$APP_ID.desktop" \
    --icon-file "$SRC_DIR/icons/hicolor/256x256/apps/$APP_ID.png" \
    --plugin qt

# AppImage root files: .DirIcon, the desktop file and the metainfo. linuxdeploy
# normally creates the first two; fill in whatever it left out.
[ -e "$APPDIR/.DirIcon" ] || cp "$SRC_DIR/icons/hicolor/256x256/apps/$APP_ID.png" "$APPDIR/.DirIcon"
[ -e "$APPDIR/$APP_ID.png" ] || cp "$SRC_DIR/icons/hicolor/256x256/apps/$APP_ID.png" "$APPDIR/$APP_ID.png"
[ -e "$APPDIR/$APP_ID.desktop" ] || cp "$APPDIR/usr/share/applications/$APP_ID.desktop" "$APPDIR/$APP_ID.desktop"
mkdir -p "$APPDIR/usr/share/metainfo"
[ -e "$APPDIR/usr/share/metainfo/$APP_ID.metainfo.xml" ] || cp "$SRC_DIR/$APP_ID.metainfo.xml" "$APPDIR/usr/share/metainfo/"

# Pack the finished AppDir
./linuxdeploy-x86_64.AppImage --appdir "$APPDIR" --output appimage

echo "AppImage created successfully!"
ls -la ./*.AppImage

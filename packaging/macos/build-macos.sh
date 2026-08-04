#!/bin/bash
# Build macOS app bundle for Free Radio.
#
# Requirements: Qt6, CMake, Ninja, macdeployqt, and a KF6 Kirigami install.
# On Homebrew, Qt is normally found under /opt/homebrew. If Kirigami is in a
# custom prefix, pass it through KDE_PREFIX_PATH, for example:
#   KDE_PREFIX_PATH=/tmp/freeradio-kde-6.28.0 ./packaging/macos/build-macos.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build-macos"
APP_BUNDLE="$BUILD_DIR/Free Radio.app"
QT_MULTIMEDIA_PREFIX="${FREERADIO_QT_MULTIMEDIA_PREFIX:-}"
FFMPEG_PREFIX="${FREERADIO_FFMPEG_PREFIX:-}"

echo "Building Free Radio for macOS..."
echo "Project directory: $PROJECT_DIR"

command -v cmake >/dev/null
command -v macdeployqt >/dev/null

# Prefer an explicitly supplied prefix list. Otherwise, make Homebrew's
# prefix available to CMake and append a custom KDE prefix when provided.
if [[ -n "${CMAKE_PREFIX_PATH:-}" ]]; then
    CMAKE_PREFIX_PATH_VALUE="$CMAKE_PREFIX_PATH"
else
    prefix_parts=()
    if command -v brew >/dev/null 2>&1; then
        prefix_parts+=("$(brew --prefix)")
    fi
    if [[ -n "${KDE_PREFIX_PATH:-}" ]]; then
        prefix_parts+=("$KDE_PREFIX_PATH")
    fi
    if [[ -n "$QT_MULTIMEDIA_PREFIX" ]]; then
        prefix_parts+=("$QT_MULTIMEDIA_PREFIX")
    fi
    CMAKE_PREFIX_PATH_VALUE="$(IFS=';'; echo "${prefix_parts[*]}")"
fi

cmake_args=(
    -S "$PROJECT_DIR/freeradio"
    -B "$BUILD_DIR"
    -G Ninja
    -DCMAKE_BUILD_TYPE=Release
    "-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES:-$(uname -m)}"
)
if [[ -n "$CMAKE_PREFIX_PATH_VALUE" ]]; then
    cmake_args+=("-DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH_VALUE")
fi
if [[ -n "$QT_MULTIMEDIA_PREFIX" ]]; then
    cmake_args+=("-DQt6Multimedia_DIR=$QT_MULTIMEDIA_PREFIX/lib/cmake/Qt6Multimedia")
fi
if [[ -n "${CMAKE_OSX_DEPLOYMENT_TARGET:-}" ]]; then
    cmake_args+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=$CMAKE_OSX_DEPLOYMENT_TARGET")
fi

# Start from a clean generated build so a previous app bundle cannot be reused.
if [[ -d "$BUILD_DIR" ]]; then
    rm -rf "$BUILD_DIR"
fi
cmake "${cmake_args[@]}"
cmake --build "$BUILD_DIR" --parallel "$(sysctl -n hw.ncpu)"

# CMake creates the executable as a real macOS application bundle.
if [[ -d "$BUILD_DIR/freeradio.app" && ! -d "$APP_BUNDLE" ]]; then
    mv "$BUILD_DIR/freeradio.app" "$APP_BUNDLE"
fi
if [[ ! -x "$APP_BUNDLE/Contents/MacOS/freeradio" ]]; then
    echo "Error: CMake did not produce $APP_BUNDLE/Contents/MacOS/freeradio" >&2
    exit 1
fi

mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$SCRIPT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Generate an icon when the host tools support it. iconutil can fail on some
# macOS/ImageMagick combinations; the app is still valid without a custom icon.
if [[ -f "$PROJECT_DIR/freeradio/icons/freeradio.icns" ]]; then
    cp "$PROJECT_DIR/freeradio/icons/freeradio.icns" "$APP_BUNDLE/Contents/Resources/"
elif command -v iconutil >/dev/null 2>&1 && command -v magick >/dev/null 2>&1; then
    iconset_parent="$(mktemp -d "${TMPDIR:-/tmp}/freeradio-iconset.XXXXXX")"
    iconset_dir="$iconset_parent/freeradio.iconset"
    mkdir -p "$iconset_dir"
    for icon_size in 16 32 128 256 512; do
        magick "$PROJECT_DIR/freeradio/icons/freeradio.png" -resize "${icon_size}x${icon_size}" \
            PNG32:"$iconset_dir/icon_${icon_size}x${icon_size}.png"
        magick "$PROJECT_DIR/freeradio/icons/freeradio.png" -resize "$((icon_size * 2))x$((icon_size * 2))" \
            PNG32:"$iconset_dir/icon_${icon_size}x${icon_size}@2x.png"
    done
    if ! iconutil -c icns "$iconset_dir" -o "$APP_BUNDLE/Contents/Resources/freeradio.icns"; then
        echo "Warning: iconutil could not create an icns file; using the system icon."
        plutil -remove CFBundleIconFile "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
    fi
else
    echo "Warning: iconutil or ImageMagick is unavailable; using the system icon."
    plutil -remove CFBundleIconFile "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
fi

# Deploy Qt libraries and QML modules. Kirigami is commonly installed in a
# custom prefix, so locate its QML import root from the CMake prefix list.
kirigami_qml_import="${KIRIGAMI_QML_IMPORT:-}"
if [[ -z "$kirigami_qml_import" ]]; then
    IFS=';' read -r -a prefix_list <<< "$CMAKE_PREFIX_PATH_VALUE"
    for prefix in "${prefix_list[@]}"; do
        if [[ -d "$prefix/lib/qml/org/kde/kirigami" ]]; then
            kirigami_qml_import="$prefix/lib/qml"
            break
        fi
    done
fi

# If a local Qt Multimedia build was supplied, put its media plugins into the
# bundle before macdeployqt scans dependencies. This allows macdeployqt to
# deploy the FFmpeg libraries used by the plugin as well.
if [[ -n "$QT_MULTIMEDIA_PREFIX" ]]; then
    custom_multimedia_plugins="$QT_MULTIMEDIA_PREFIX/share/qt/plugins/multimedia"
    if [[ ! -d "$custom_multimedia_plugins" ]]; then
        echo "Error: Qt Multimedia plugin directory not found: $custom_multimedia_plugins" >&2
        exit 1
    fi
    mkdir -p "$APP_BUNDLE/Contents/PlugIns/multimedia"
    cp "$custom_multimedia_plugins"/*.dylib "$APP_BUNDLE/Contents/PlugIns/multimedia/"
fi

macdeployqt_args=(
    "$APP_BUNDLE"
    "-qmldir=$PROJECT_DIR/freeradio/contents/ui"
    -verbose=1
)
if [[ -n "$kirigami_qml_import" ]]; then
    macdeployqt_args+=("-qmlimport=$kirigami_qml_import")
else
    echo "Warning: Kirigami QML import root was not found; the bundled app may not start."
fi
if [[ -z "$FFMPEG_PREFIX" && -n "$QT_MULTIMEDIA_PREFIX" ]] && command -v brew >/dev/null 2>&1; then
    FFMPEG_PREFIX="$(brew --prefix ffmpeg 2>/dev/null || true)"
fi
if [[ -n "$FFMPEG_PREFIX" && -d "$FFMPEG_PREFIX/lib" ]]; then
    macdeployqt_args+=("-libpath=$FFMPEG_PREFIX/lib")
fi
macdeployqt "${macdeployqt_args[@]}"

# Ad-hoc sign the bundle. Without ANY signature, Apple Silicon (arm64) kills the
# process on launch ("Killed: 9") before the window can appear -- this is the
# "no window, not in running apps" symptom. The "-" identity is a free ad-hoc
# signature: no Apple Developer license, no notarization required.
# NOTE: this does NOT clear Gatekeeper quarantine on a downloaded copy. After
# installing, users must run:  xattr -dr com.apple.quarantine "/Applications/Free Radio.app"
# (or System Settings -> Privacy & Security -> Open Anyway).
codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --deep --strict --verbose "$APP_BUNDLE"

# Create DMG
hdiutil create -volname "Free Radio" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$BUILD_DIR/FreeRadio-2.0.0-macOS.dmg"

echo "macOS build complete!"
echo "Reminder: ad-hoc signed only. Tell users to clear quarantine after install:"
echo "  xattr -dr com.apple.quarantine \"/Applications/Free Radio.app\""
ls -la "$BUILD_DIR"/*.dmg

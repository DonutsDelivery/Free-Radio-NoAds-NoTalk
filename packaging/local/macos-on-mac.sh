#!/usr/bin/env bash
# Runs on the MacBook, inside a source snapshot staged by build-macos.sh. Builds the
# arm64 DMG under the Mac-local build lock that DonutStudio's ./build.sh also takes.
# Usage: macos-on-mac.sh <work-dir>
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
WORK=$1
source "$SRC/packaging/local/versions.env"
APP_VERSION="$(sed -n 's/^project(DonutRadio VERSION \([0-9.]*\)).*/\1/p' "$SRC/freeradio/CMakeLists.txt")"
CLT=/Library/Developer/CommandLineTools
export PATH="$CLT/usr/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export CC="$CLT/usr/bin/clang" CXX="$CLT/usr/bin/clang++" SDKROOT="$CLT/SDKs/MacOSX.sdk"
JOBS=${JOBS:-3}
CACHE=$HOME/build/donutradio-release
QT=$CACHE/Qt/$QT_VERSION/macos
KDE=$CACHE/kde-$KF_VERSION-qt$QT_VERSION
FF=$CACHE/ffmpeg-8.0.3-arm64
# Keep Homebrew's own Qt, ECM and FFmpeg out of every find_package.
IGNORE="-DCMAKE_IGNORE_PREFIX_PATH=/opt/homebrew;/usr/local"

# Take /tmp/arbit-build.lock for the whole build, waiting up to MAC_BUILD_WAIT_SECONDS.
if [[ -z "${DONUTRADIO_MAC_LOCKED:-}" ]]; then
    exec /usr/bin/python3 - "$0" "$@" <<'PY'
import fcntl, os, sys, time
lock = open("/tmp/arbit-build.lock", "a+")
deadline = time.monotonic() + int(os.environ.get("MAC_BUILD_WAIT_SECONDS", "21600"))
while True:
    try:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB); break
    except BlockingIOError:
        if time.monotonic() >= deadline: sys.exit("Another MacBook build owns /tmp/arbit-build.lock")
        time.sleep(1)
os.environ["DONUTRADIO_MAC_LOCKED"] = "1"
os.execv("/bin/bash", ["bash", *sys.argv[1:]])
PY
fi

mkdir -p "$CACHE" "$WORK"
if [[ ! -x "$QT/bin/macdeployqt" ]]; then
    /usr/bin/python3 -m venv "$CACHE/venv"
    "$CACHE/venv/bin/pip" install -q "aqtinstall==$AQT_VERSION"
    "$CACHE/venv/bin/aqt" install-qt mac desktop "$QT_VERSION" clang_64 -m qtshadertools -O "$CACHE/Qt"
fi

if [[ ! -f "$KDE/.done" ]]; then
    rm -rf "$KDE" "$CACHE/kde-src" && mkdir -p "$CACHE/kde-src"
    for repo in extra-cmake-modules kirigami; do
        git clone -q --depth 1 --branch "v$KF_VERSION" "https://invent.kde.org/frameworks/$repo.git" "$CACHE/kde-src/$repo"
        cmake -S "$CACHE/kde-src/$repo" -B "$CACHE/kde-src/$repo-build" -G Ninja "$IGNORE" \
            -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 \
            -DCMAKE_PREFIX_PATH="$QT;$KDE" -DCMAKE_INSTALL_PREFIX="$KDE" -DBUILD_TESTING=OFF -DBUILD_QCH=OFF
        cmake --build "$CACHE/kde-src/$repo-build" -j "$JOBS"
        cmake --install "$CACHE/kde-src/$repo-build"
    done
    touch "$KDE/.done"
fi

if [[ ! -f "$FF/.done" ]]; then
    rm -rf "$FF" "$CACHE/ffmpeg-build"
    "$SRC/scripts/ffmpeg/fetch-ffmpeg.sh" --cache "$CACHE/downloads"
    "$SRC/scripts/ffmpeg/build-native.sh" --prefix "$FF" --source-dir "$CACHE/downloads/ffmpeg-8.0.3" \
        --build-dir "$CACHE/ffmpeg-build" --jobs "$JOBS"
    touch "$FF/.done"
fi

B=$WORK/build
rm -rf "$B"
cmake -S "$SRC/freeradio" -B "$B" -G Ninja "$IGNORE" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_PREFIX_PATH="$QT;$KDE" -DBUILD_TESTING=OFF \
    -DFREERADIO_FFMPEG_PROVIDER=EXPLICIT -DFREERADIO_FFMPEG_INCLUDE_DIR="$FF/include" \
    -DFREERADIO_AVFORMAT_LIBRARY="$FF/lib/libavformat.dylib" \
    -DFREERADIO_AVCODEC_LIBRARY="$FF/lib/libavcodec.dylib" \
    -DFREERADIO_AVUTIL_LIBRARY="$FF/lib/libavutil.dylib" \
    -DFREERADIO_SWRESAMPLE_LIBRARY="$FF/lib/libswresample.dylib"
cmake --build "$B" -j "$JOBS"
STAGE=$WORK/stage
rm -rf "$STAGE"
cmake --install "$B" --prefix "$STAGE"

# CMake names the bundle donutradio.app; the file system ignores case, so rename in two steps.
APP=$WORK/DonutRadio.app
rm -rf "$APP" "$WORK/tmp.app"
mv "$STAGE/donutradio.app" "$WORK/tmp.app" && mv "$WORK/tmp.app" "$APP"
cp "$SRC/packaging/macos/Info.plist" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" -c "Set :CFBundleVersion $APP_VERSION" "$APP/Contents/Info.plist"

ICONSET=$WORK/donutradio.iconset
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
    sips -z $s $s "$SRC/freeradio/icons/donutradio.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) "$SRC/freeradio/icons/donutradio.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/donutradio.icns"

KDE_QML="$(dirname "$(find "$KDE" -type d -path '*/qml/org/kde/kirigami' | head -1)")"
KDE_QML="${KDE_QML%/org/kde}"
export DYLD_LIBRARY_PATH="$FF/lib:$KDE/lib"
"$QT/bin/macdeployqt" "$APP" -qmldir="$SRC/freeradio/contents/ui" -qmlimport="$KDE_QML" \
    -qmlimport="$APP/Contents/Resources/qml" -libpath="$FF/lib" -libpath="$KDE/lib" -verbose=1
unset DYLD_LIBRARY_PATH

# macdeployqt rewrites install names, which breaks signatures; Apple Silicon refuses to
# load unsigned code, so ad-hoc sign the whole bundle afterwards.
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

# Every library must resolve inside the bundle.
bad="$(find "$APP" -type f \( -perm -111 -o -name '*.dylib' \) -exec otool -L {} + 2>/dev/null \
    | grep -E '^\s+/(opt/homebrew|usr/local|Users)/' || true)"
[[ -z "$bad" ]] || { echo "Bundle links outside itself:" >&2; echo "$bad" >&2; exit 1; }
lipo -info "$APP/Contents/MacOS/donutradio"

# Launch the bundled executable; it must stay up.
"$APP/Contents/MacOS/donutradio" >"$WORK/smoke.log" 2>&1 &
pid=$!
sleep 8
if ! kill -0 "$pid" 2>/dev/null; then echo "App exited at launch:" >&2; cat "$WORK/smoke.log" >&2; exit 1; fi
kill "$pid"; wait "$pid" 2>/dev/null || true
grep -iE 'module .* not (found|installed)|cannot load library' "$WORK/smoke.log" && { echo "QML import failure" >&2; exit 1; }

DMG=$WORK/DonutRadio-macOS.dmg
rm -f "$DMG"
hdiutil create -volname DonutRadio -srcfolder "$APP" -ov -format UDZO "$DMG"
hdiutil verify "$DMG"
echo MACOS_BUILD_OK

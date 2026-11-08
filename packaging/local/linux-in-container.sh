#!/usr/bin/env bash
# Runs inside the Linux release image. /src is the read-only checkout, /cache keeps
# the dependency and build trees between runs, /out receives the release files.
set -euo pipefail
source /src/packaging/local/versions.env
APP_ID=online.donutsdelivery.DonutRadio
JOBS=${JOBS:-$(nproc)}
KDE=/cache/kde-$KF_VERSION-qt$QT_VERSION
FF=/cache/ffmpeg-8.0.3
export PATH="$QT_ROOT/bin:$PATH" LANG=C.UTF-8 LC_ALL=C.UTF-8

# ECM and Kirigami, built once per pin.
if [[ ! -f "$KDE/.done" ]]; then
    rm -rf "$KDE" /cache/kde-src && mkdir -p /cache/kde-src
    for repo in extra-cmake-modules kirigami; do
        git clone -q --depth 1 --branch "v$KF_VERSION" "https://invent.kde.org/frameworks/$repo.git" "/cache/kde-src/$repo"
        cmake -S "/cache/kde-src/$repo" -B "/cache/kde-src/$repo-build" -G Ninja \
            -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$QT_ROOT;$KDE" \
            -DCMAKE_INSTALL_PREFIX="$KDE" -DBUILD_TESTING=OFF -DBUILD_QCH=OFF
        cmake --build "/cache/kde-src/$repo-build" -j "$JOBS"
        cmake --install "/cache/kde-src/$repo-build"
    done
    touch "$KDE/.done"
fi

# The pinned LGPL FFmpeg, built once.
if [[ ! -f "$FF/.done" ]]; then
    rm -rf "$FF" /cache/ffmpeg-build
    /src/scripts/ffmpeg/fetch-ffmpeg.sh --cache /cache/downloads
    /src/scripts/ffmpeg/build-native.sh --prefix "$FF" --source-dir /cache/downloads/ffmpeg-8.0.3 \
        --build-dir /cache/ffmpeg-build --jobs "$JOBS"
    touch "$FF/.done"
fi

# The app, configured from scratch each run so no stale cache survives.
B=/cache/app-build
rm -rf "$B" /cache/AppDir
cmake -S /src/freeradio -B "$B" -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$QT_ROOT;$KDE" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib \
    -DDONUTRADIO_INSTALL_PLASMOID=OFF -DBUILD_TESTING=OFF \
    -DFREERADIO_FFMPEG_PROVIDER=EXPLICIT -DFREERADIO_FFMPEG_INCLUDE_DIR="$FF/include" \
    -DFREERADIO_AVFORMAT_LIBRARY="$FF/lib/libavformat.so" \
    -DFREERADIO_AVCODEC_LIBRARY="$FF/lib/libavcodec.so" \
    -DFREERADIO_AVUTIL_LIBRARY="$FF/lib/libavutil.so" \
    -DFREERADIO_SWRESAMPLE_LIBRARY="$FF/lib/libswresample.so"
cmake --build "$B" -j "$JOBS"
DESTDIR=/cache/AppDir cmake --install "$B"

# AppImage. linuxdeploy copies FFmpeg and Qt libraries; the Qt plugin deploys the
# QML imports the app uses, including Kirigami from its own prefix.
TOOLS=/cache/tools; mkdir -p "$TOOLS"
for t in linuxdeploy linuxdeploy-plugin-qt; do
    [[ -x "$TOOLS/$t-x86_64.AppImage" ]] || curl -fsSL -o "$TOOLS/$t-x86_64.AppImage" \
        "https://github.com/linuxdeploy/$t/releases/download/continuous/$t-x86_64.AppImage"
    chmod +x "$TOOLS/$t-x86_64.AppImage"
done
sha256sum "$TOOLS"/*.AppImage
KDE_QML="$(dirname "$(find "$KDE" -type d -path '*/qml/org/kde/kirigami' | head -1)")"
KDE_QML="${KDE_QML%/org/kde}"
export APPIMAGE_EXTRACT_AND_RUN=1 QMAKE="$QT_ROOT/bin/qmake"
# xcb only by default; add Wayland for Wayland desktops and offscreen for the smoke start.
export EXTRA_PLATFORM_PLUGINS="libqwayland-egl.so;libqwayland-generic.so;libqoffscreen.so"
export QML_SOURCES_PATHS=/src/freeradio/contents/ui
export QML_MODULES_PATHS="/cache/AppDir/usr/lib/qt6/qml:$KDE_QML"
export LD_LIBRARY_PATH="$FF/lib:$KDE/lib:$KDE/lib/x86_64-linux-gnu:$QT_ROOT/lib"
export LDAI_OUTPUT=/cache/DonutRadio-Linux-x86_64.AppImage
ICON=/src/freeradio/icons/hicolor/256x256/apps/$APP_ID.png
cd /cache
rm -f "$LDAI_OUTPUT"
# AppImageHub rejects an AppImage without a .DirIcon. A real file, not a link.
rm -f /cache/AppDir/.DirIcon && install -m 644 "$ICON" /cache/AppDir/.DirIcon
"$TOOLS/linuxdeploy-x86_64.AppImage" --appdir /cache/AppDir \
    --desktop-file "/cache/AppDir/usr/share/applications/$APP_ID.desktop" \
    --icon-file "$ICON" --plugin qt --output appimage

# Every FFmpeg and Kirigami library must come from the bundle.
for lib in libavformat.so.62 libavcodec.so.62 libavutil.so.60 libswresample.so.6; do
    test -e "/cache/AppDir/usr/lib/$lib" || { echo "AppImage is missing $lib" >&2; exit 1; }
done
ls /cache/AppDir/usr/lib/libKirigami*.so* >/dev/null || { echo "AppImage is missing Kirigami" >&2; exit 1; }
find /cache/AppDir/usr -path '*org/kde/kirigami/qmldir' | grep -q . || { echo "Kirigami QML module missing" >&2; exit 1; }

# The AppImage needs a .DirIcon, the desktop file and the AppStream metainfo.
APPIMAGE_EXTRACT_AND_RUN=1 "$LDAI_OUTPUT" --appimage-extract >/dev/null
for f in .DirIcon "$APP_ID.desktop" "usr/share/metainfo/$APP_ID.metainfo.xml"; do
    test -e "squashfs-root/$f" || { echo "AppImage is missing $f" >&2; exit 1; }
done
grep -q "<id>$APP_ID</id>" "squashfs-root/usr/share/metainfo/$APP_ID.metainfo.xml" \
    || { echo "metainfo ID is not $APP_ID" >&2; exit 1; }
rm -rf squashfs-root

# The packaged app must start and stay up.
QT_QPA_PLATFORM=offscreen "$LDAI_OUTPUT" --appimage-extract-and-run >/cache/smoke.log 2>&1 &
pid=$!
sleep 8
if ! kill -0 "$pid" 2>/dev/null; then
    echo "AppImage exited during the smoke start:" >&2; cat /cache/smoke.log >&2; exit 1
fi
kill "$pid"; wait "$pid" 2>/dev/null || true
grep -iE 'module .* not (found|installed)|cannot load library' /cache/smoke.log && { echo "QML import failure" >&2; exit 1; }

# Plasma widget archive.
rm -f /cache/donutradio.plasmoid
(cd /src/freeradio && zip -qr /cache/donutradio.plasmoid metadata.json contents \
    -x '*.backup' -x 'contents/ui/radiodata_radcap.js')

cp /cache/DonutRadio-Linux-x86_64.AppImage /cache/donutradio.plasmoid /out/
echo LINUX_RELEASE_OK

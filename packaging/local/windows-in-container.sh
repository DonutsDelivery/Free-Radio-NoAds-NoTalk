#!/usr/bin/env bash
# Runs inside the Windows release image as root, so Wine uses the image's prefix.
# /src is the read-only checkout, /cache keeps dependency and build trees, /out gets
# the portable zip. Everything is compiled by the real MSVC under Wine.
set -euo pipefail
source /src/packaging/local/versions.env
JOBS=${JOBS:-4}
export WINEDEBUG=-all
QT_WIN="$(ls -d /opt/Qt/"$QT_VERSION"/msvc20*_64 | head -1)"
QT_HOST=/opt/Qt/$QT_VERSION/gcc_64
KDE=/cache/kde-$KF_VERSION-qt$QT_VERSION
FF=/cache/ffmpeg-8.0.3
trap '[ "${HOST_UID:-0}" = 0 ] || chown -R "$HOST_UID:$HOST_GID" /cache /out 2>/dev/null || true' EXIT

# CC=cl + CMAKE_SYSTEM_NAME=Windows is msvc-wine's documented cross setup. No forced
# response files: msvc-wine rewrites /unix/paths to z:/unix/paths only on the command
# line, and link.exe reads an unconverted /opt/Qt/...lib inside a .rsp as an option.
cross_cmake() {
    CC=cl CXX=cl cmake -G Ninja -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_BUILD_TYPE=Release \
        -DQT_HOST_PATH="$QT_HOST" "$@"
}

if [[ ! -f "$KDE/.done" ]]; then
    rm -rf "$KDE" /cache/kde-src && mkdir -p /cache/kde-src
    for repo in extra-cmake-modules kirigami; do
        git clone -q --depth 1 --branch "v$KF_VERSION" "https://invent.kde.org/frameworks/$repo.git" "/cache/kde-src/$repo"
        cross_cmake -S "/cache/kde-src/$repo" -B "/cache/kde-src/$repo-build" \
            -DCMAKE_PREFIX_PATH="$QT_WIN;$KDE" -DCMAKE_INSTALL_PREFIX="$KDE" \
            -DBUILD_TESTING=OFF -DBUILD_QCH=OFF
        cmake --build "/cache/kde-src/$repo-build" -j "$JOBS"
        cmake --install "/cache/kde-src/$repo-build"
    done
    touch "$KDE/.done"
fi

# Pinned LGPL FFmpeg with MSVC. Windows has no pthreads, so it uses Win32 threads.
if [[ ! -f "$FF/.done" ]]; then
    rm -rf "$FF" /cache/ffmpeg-build && mkdir -p /cache/ffmpeg-build
    /src/scripts/ffmpeg/fetch-ffmpeg.sh --cache /cache/downloads
    source /src/scripts/ffmpeg/configure-common.sh
    mapfile -t flags < <(ffmpeg_common_flags | sed 's/^--enable-pthreads$/--enable-w32threads/')
    (cd /cache/ffmpeg-build && /cache/downloads/ffmpeg-8.0.3/configure --prefix="$FF" \
        --toolchain=msvc --target-os=win64 --arch=x86_64 --enable-cross-compile \
        --host-cc=gcc --x86asmexe=nasm "${flags[@]}" && make -j "$JOBS" && make install)
    touch "$FF/.done"
fi

B=/cache/app-build
STAGE=/cache/stage
rm -rf "$B" "$STAGE"
cross_cmake -S /src/freeradio -B "$B" -DCMAKE_PREFIX_PATH="$QT_WIN;$KDE" \
    -DCMAKE_INSTALL_PREFIX="$STAGE" -DBUILD_TESTING=OFF \
    -DFREERADIO_FFMPEG_PROVIDER=EXPLICIT -DFREERADIO_FFMPEG_INCLUDE_DIR="$FF/include" \
    -DFREERADIO_AVFORMAT_LIBRARY="$FF/bin/avformat.lib" \
    -DFREERADIO_AVCODEC_LIBRARY="$FF/bin/avcodec.lib" \
    -DFREERADIO_AVUTIL_LIBRARY="$FF/bin/avutil.lib" \
    -DFREERADIO_SWRESAMPLE_LIBRARY="$FF/bin/swresample.lib"
cmake --build "$B" -j "$JOBS"
cmake --install "$B"

# Deploy Qt next to the exe with the MSVC Qt's own windeployqt, run under Wine.
D="$STAGE/bin"
cp "$FF"/bin/*.dll "$D/"
cp "$KDE"/bin/*.dll "$D/" 2>/dev/null || true
KDE_QML="$(dirname "$(find "$KDE" -type d -path '*/qml/org/kde/kirigami' | head -1)")"
KDE_QML="${KDE_QML%/org/kde}"
wine64 "$QT_WIN/bin/windeployqt.exe" --release --no-translations --no-compiler-runtime \
    --qmldir "$(winepath -w /src/freeradio/contents/ui)" \
    --qmlimport "$(winepath -w "$KDE_QML")" --qmlimport "$(winepath -w "$D/qml")" \
    "$(winepath -w "$D/donutradio.exe")"
# The portable zip carries the VC++ runtime DLLs; the installer also runs vc_redist.
crt="$(find /opt/msvc -type d -path '*Redist/MSVC/*/x64/Microsoft.VC*.CRT' | grep -v onecore | sort | tail -1)"
[[ -n "$crt" ]] || { echo "MSVC runtime DLLs not found" >&2; exit 1; }
cp "$crt"/*.dll "$D/"
# windeployqt finds the Kirigami import but not always its plugin DLLs; copy the module.
mkdir -p "$D/qml/org/kde"
cp -r "$KDE_QML/org/kde/kirigami" "$D/qml/org/kde/"
mkdir -p "$D/licenses"
cp /src/LICENSES/FFmpeg-* "$D/licenses/"
cp "$FF/share/freeradio/licenses/"* "$D/licenses/" 2>/dev/null || true

for dll in avformat-62.dll avcodec-62.dll avutil-60.dll swresample-6.dll Qt6Core.dll Qt6Quick.dll; do
    test -f "$D/$dll" || { echo "Windows package is missing $dll" >&2; exit 1; }
done
ls "$D"/KF6Kirigami*.dll "$D"/Kirigami*.dll >/dev/null 2>&1 || ls "$D" | grep -i kirigami || { echo "Kirigami DLL missing" >&2; exit 1; }

# Smoke start under Wine without a display.
(cd "$D" && QT_QPA_PLATFORM=offscreen timeout 25 wine64 donutradio.exe >/cache/smoke.log 2>&1) && status=0 || status=$?
if [[ $status != 124 ]]; then
    echo "donutradio.exe exited with $status during the smoke start:" >&2; tail -40 /cache/smoke.log >&2; exit 1
fi
grep -iE 'module .* not (found|installed)|cannot load library' /cache/smoke.log && { echo "QML import failure" >&2; exit 1; }

rm -rf /cache/DonutRadio /out/DonutRadio-Windows-Portable-x64.zip /out/windows-dist
cp -r "$D" /cache/DonutRadio
(cd /cache && zip -qr /out/DonutRadio-Windows-Portable-x64.zip DonutRadio)
cp -r "$D" /out/windows-dist
echo WINDOWS_BUILD_OK

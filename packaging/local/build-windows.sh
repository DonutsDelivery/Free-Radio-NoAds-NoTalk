#!/usr/bin/env bash
# Build the Windows release files locally, no CI, with the real MSVC under Wine:
#   dist/DonutRadio-Windows-Portable-x64.zip and dist/DonutRadio-Setup-x64.exe
# Usage: packaging/local/build-windows.sh [--rebuild-image]
# Needs DonutStudio's images: arbit-windows-build:msvc-wine (Dockerfile.windows-msvc-wine)
# and arbit-inno-build (Dockerfile.windows-installer). Waits for the host build token for
# HOST_HEAVY_BUILD_WAIT_SECONDS (default: fail at once).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
enter_build_token "$(readlink -f "${BASH_SOURCE[0]}")" "$@"
require_clean_tree

BASE="${DONUTRADIO_MSVC_WINE_IMAGE:-arbit-windows-build:msvc-wine}"
INNO="${DONUTRADIO_INNO_IMAGE:-arbit-inno-build}"
IMAGE="donutradio-windows-release:qt$QT_VERSION"
for img in "$BASE" "$INNO"; do
    docker image inspect "$img" >/dev/null 2>&1 || { echo "Missing Docker image $img (see DonutStudio's Dockerfiles)" >&2; exit 1; }
done
if [[ "${1:-}" == --rebuild-image ]] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    docker build -t "$IMAGE" --build-arg BASE="$BASE" --build-arg QT_VERSION="$QT_VERSION" \
        --build-arg AQT_VERSION="$AQT_VERSION" -f "$REPO/packaging/local/Dockerfile.windows" "$REPO/packaging/local"
fi

CACHE="$CACHE_ROOT/windows"
mkdir -p "$CACHE" "$DIST"
rm -rf "$DIST/DonutRadio-Windows-Portable-x64.zip" "$DIST/DonutRadio-Setup-x64.exe" "$DIST/windows-dist"
docker run --rm -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" -e JOBS="${JOBS:-4}" \
    -v "$REPO:/src:ro" -v "$CACHE:/cache" -v "$DIST:/out" \
    "$IMAGE" /src/packaging/local/windows-in-container.sh

# Installer: Inno Setup under Wine, from a staging copy laid out like the repo so the
# script's relative paths resolve. The VC++ runtime installer is cached.
REDIST="$CACHE/vc_redist.x64.exe"
[[ -s "$REDIST" ]] || curl -fsSL -o "$REDIST" https://aka.ms/vs/17/release/vc_redist.x64.exe
ISS_STAGE="$CACHE/inno"
rm -rf "$ISS_STAGE" && mkdir -p "$ISS_STAGE/packaging/windows" "$ISS_STAGE/freeradio/icons"
cp "$REPO/packaging/windows/installer.iss" "$ISS_STAGE/packaging/windows/"
cp -r "$DIST/windows-dist" "$ISS_STAGE/packaging/windows/dist"
cp "$REDIST" "$ISS_STAGE/packaging/windows/"
cp "$REPO/freeradio/icons/donutradio.ico" "$ISS_STAGE/freeradio/icons/"
docker run --rm -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    -v "$ISS_STAGE:/work" -v "$DIST:/out" -w /work "$INNO" bash -lc '
    set -e
    ISCC="/root/.wine/drive_c/Program Files (x86)/Inno Setup 6/ISCC.exe"
    WINEDEBUG=-all xvfb-run -a wine "$ISCC" "/DMyAppVersion='"$APP_VERSION"'" "/OZ:\\out" \
        "Z:\\work\\packaging\\windows\\installer.iss"
    chown "$HOST_UID:$HOST_GID" /out/DonutRadio-Setup-x64.exe; chown -R "$HOST_UID:$HOST_GID" /work'
rm -rf "$DIST/windows-dist"
write_receipt windows-receipt.txt DonutRadio-Windows-Portable-x64.zip DonutRadio-Setup-x64.exe
cat "$DIST/windows-receipt.txt"

#!/usr/bin/env bash
# Build the Linux release files locally in Docker, no CI:
#   dist/DonutRadio-Linux-x86_64.AppImage and dist/donutradio.plasmoid
# Usage: packaging/local/build-linux.sh [--rebuild-image]
# Waits for the host build token for HOST_HEAVY_BUILD_WAIT_SECONDS (default: fail at once).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
enter_build_token "$(readlink -f "${BASH_SOURCE[0]}")" "$@"
require_clean_tree

IMAGE="donutradio-linux-release:qt$QT_VERSION"
if [[ "${1:-}" == --rebuild-image ]] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    docker build -t "$IMAGE" --build-arg QT_VERSION="$QT_VERSION" --build-arg AQT_VERSION="$AQT_VERSION" \
        -f "$REPO/packaging/local/Dockerfile.linux" "$REPO/packaging/local"
fi

CACHE="$CACHE_ROOT/linux"
mkdir -p "$CACHE" "$DIST"
rm -f "$DIST/DonutRadio-Linux-x86_64.AppImage" "$DIST/donutradio.plasmoid"
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/cache -e JOBS="${JOBS:-8}" \
    -v "$SRC_SNAPSHOT:/src:ro" -v "$CACHE:/cache" -v "$DIST:/out" \
    "$IMAGE" /src/packaging/local/linux-in-container.sh
write_receipt linux-receipt.txt DonutRadio-Linux-x86_64.AppImage donutradio.plasmoid
cat "$DIST/linux-receipt.txt"

#!/usr/bin/env bash
# Build the Snap Store package from the DonutRadio AppImage release, in an Ubuntu 24.04
# container with snapcraft --destructive-mode (this host is not Ubuntu and has no LXD).
# Usage: packaging/snap/build-snap.sh [output-dir]      (default: dist/)
# Needs the snapcraft and core24 snaps on the host, whose files are mounted read-only
# into the container, and the host build gate for the Docker run.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO="$(cd "$HERE/../.." && pwd -P)"
OUT="$(realpath -m "${1:-$REPO/dist}")"
GATE="${HOST_HEAVY_BUILD_GATE:-$HOME/.local/bin/host-heavy-build}"
if [[ -z "${HOST_HEAVY_BUILD_TOKEN:-}" ]]; then
    [[ -x "$GATE" ]] || { echo "Builds need the host build gate: $GATE" >&2; exit 75; }
    exec "$GATE" run --project DonutRadio --worktree "$REPO" \
        --wait "${HOST_HEAVY_BUILD_WAIT_SECONDS:-0}" -- "${BASH_SOURCE[0]}" "$@"
fi
SNAPCRAFT_DIR="$(readlink -f /snap/snapcraft/current)"
CORE24_DIR="$(readlink -f /snap/core24/current)"
[[ -d "$SNAPCRAFT_DIR" && -d "$CORE24_DIR" ]] || { echo "Install the snapcraft and core24 snaps first." >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/project/snap" "$OUT"
cp "$HERE/snapcraft.yaml" "$WORK/project/snap/"
cp -r "$HERE/gui" "$WORK/project/snap/gui"

# snapcraft prime runs in the container. The container has no snap tool, so the host
# packs the primed tree below.
docker run --rm -v "$WORK/project:/project" \
    -v "$SNAPCRAFT_DIR:/snap/snapcraft/current:ro" -v "$CORE24_DIR:/snap/core24/current:ro" \
    -e SNAP=/snap/snapcraft/current -e SNAP_NAME=snapcraft -e DEBIAN_FRONTEND=noninteractive \
    -w /project ubuntu:24.04 bash -euxc '
        apt-get update
        apt-get install -y --no-install-recommends ca-certificates git sudo
        /snap/snapcraft/current/bin/python /snap/snapcraft/current/bin/snapcraft prime --destructive-mode
        chown -R '"$(id -u):$(id -g)"' /project'
chmod -R a+rX "$WORK/project/prime"
snap pack --check-skeleton "$WORK/project/prime"
snap pack "$WORK/project/prime" "$OUT"
ls -l "$OUT"/donutradio_*_amd64.snap

# Shared helpers for the local release wrappers. Source from a wrapper script.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=versions.env
source "$REPO/packaging/local/versions.env"
APP_VERSION="$(sed -n 's/^project(DonutRadio VERSION \([0-9.]*\)).*/\1/p' "$REPO/freeradio/CMakeLists.txt")"
CACHE_ROOT="${DONUTRADIO_RELEASE_CACHE_ROOT:-$HOME/.cache/donutradio-release}"
DIST="${DONUTRADIO_DIST_DIR:-$REPO/dist}"

# Re-run the calling script under the Linux host-wide build token. Every compile on
# this host shares that token with DonutStudio, LocalBooru and the other projects.
enter_build_token() {
    [[ -n "${HOST_HEAVY_BUILD_TOKEN:-}" ]] && return 0
    local gate="${HOST_HEAVY_BUILD_GATE:-$HOME/.local/bin/host-heavy-build}"
    [[ -x "$gate" ]] || { echo "Builds need the host build gate: $gate" >&2; exit 75; }
    exec "$gate" run --project DonutRadio --worktree "$REPO" \
        --wait "${HOST_HEAVY_BUILD_WAIT_SECONDS:-0}" -- "$@"
}

# Refuse to build release files from uncommitted source, and record what was built.
require_clean_tree() {
    if [[ -n "$(git -C "$REPO" status --porcelain --untracked-files=no)" ]]; then
        echo "Refusing to build: tracked files have uncommitted changes." >&2
        git -C "$REPO" status --short --untracked-files=no >&2
        exit 1
    fi
    SOURCE_COMMIT="$(git -C "$REPO" rev-parse HEAD)"
    # Build from an exported copy of the commit, so edits to the checkout during a
    # long build cannot leak into the release files.
    SRC_SNAPSHOT="$CACHE_ROOT/src/$SOURCE_COMMIT"
    if [[ ! -f "$SRC_SNAPSHOT/.complete" ]]; then
        rm -rf "$SRC_SNAPSHOT" && mkdir -p "$SRC_SNAPSHOT"
        git -C "$REPO" archive --format=tar HEAD | tar -xf - -C "$SRC_SNAPSHOT"
        touch "$SRC_SNAPSHOT/.complete"
    fi
}

write_receipt() {
    local name=$1; shift
    {
        echo "app_version=$APP_VERSION"
        echo "source_commit=$SOURCE_COMMIT"
        echo "qt=$QT_VERSION kf=$KF_VERSION"
        echo "built_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        (cd "$DIST" && sha256sum "$@")
    } > "$DIST/$name"
}

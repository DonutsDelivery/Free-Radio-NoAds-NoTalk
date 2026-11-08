#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "${script_dir}/../.." && pwd)
# shellcheck source=configure-common.sh
source "${script_dir}/configure-common.sh"

usage() {
    printf 'Usage: %s --prefix DIR [--source-dir DIR] [--build-dir DIR] [--jobs N] [--configure-only] [--dry-run]\n' "$0"
}

prefix=""
source_dir=""
build_dir=""
jobs=""
configure_only=0
dry_run=0
while (($#)); do
    case "$1" in
        --prefix) prefix=$2; shift 2 ;;
        --source-dir) source_dir=$2; shift 2 ;;
        --build-dir) build_dir=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        --configure-only) configure_only=1; shift ;;
        --dry-run) dry_run=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done
[[ -n "$prefix" ]] || { usage >&2; exit 2; }
source_dir=${source_dir:-"${repo_dir}/build/downloads/ffmpeg-${FREERADIO_FFMPEG_VERSION}"}
build_dir=${build_dir:-"${repo_dir}/build/ffmpeg-native"}
if [[ -z "$jobs" ]]; then
    jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || printf 1)
fi
case "$(uname -m)" in
    arm64|aarch64) ffmpeg_arch=aarch64 ;;
    x86_64|amd64) ffmpeg_arch=x86_64 ;;
    *) printf 'Unsupported native architecture: %s\n' "$(uname -m)" >&2; exit 1 ;;
esac

flags=()
while IFS= read -r flag; do flags+=("$flag"); done < <(ffmpeg_common_flags)
command=("${source_dir}/configure" "--prefix=${prefix}" "--arch=${ffmpeg_arch}" "${flags[@]}")
if ((dry_run)); then
    printf 'License: LGPL-2.1-or-later\n'
    printf 'Configure:'; printf ' %q' "${command[@]}"; printf '\n'
    printf 'Build: make -C %q -j %q\n' "$build_dir" "$jobs"
    exit 0
fi
if [[ ! -x "${source_dir}/configure" ]]; then
    source_dir=$("${script_dir}/fetch-ffmpeg.sh" --source-dir "$source_dir")
    command=("${source_dir}/configure" "--prefix=${prefix}" "--arch=${ffmpeg_arch}" "${flags[@]}")
fi
mkdir -p "$build_dir" "$prefix"
(
    cd "$build_dir"
    "${command[@]}"
    if ((configure_only == 0)); then
        make -j "$jobs"
        make install
    fi
)
if ((configure_only)); then exit 0; fi
mkdir -p "${prefix}/share/freeradio/licenses"
install -m 0644 "${source_dir}/COPYING.LGPLv2.1" \
    "${prefix}/share/freeradio/licenses/FFmpeg-LGPL-2.1-or-later.txt"
install -m 0644 "${repo_dir}/LICENSES/FFmpeg-NOTICE.txt" \
    "${prefix}/share/freeradio/licenses/FFmpeg-NOTICE.txt"
printf 'Installed FFmpeg %s to %s\n' "$FREERADIO_FFMPEG_VERSION" "$prefix"

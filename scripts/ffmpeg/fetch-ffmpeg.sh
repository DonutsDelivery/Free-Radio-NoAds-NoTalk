#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=configure-common.sh
source "${script_dir}/configure-common.sh"

usage() {
    printf 'Usage: %s [--cache DIR] [--source-dir DIR] [--dry-run]\n' "$0"
}

cache_dir="${FREERADIO_DOWNLOAD_CACHE:-${script_dir}/../../build/downloads}"
source_dir=""
dry_run=0
while (($#)); do
    case "$1" in
        --cache) cache_dir=$2; shift 2 ;;
        --source-dir) source_dir=$2; shift 2 ;;
        --dry-run) dry_run=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done
source_dir=${source_dir:-"${cache_dir}/ffmpeg-${FREERADIO_FFMPEG_VERSION}"}
archive="${cache_dir}/${FREERADIO_FFMPEG_ARCHIVE}"

if ((dry_run)); then
    printf 'download: %s\nsha256:  %s\narchive: %s\nsource:   %s\n' \
        "${FREERADIO_FFMPEG_URL}" "${FREERADIO_FFMPEG_SHA256}" "$archive" "$source_dir"
    exit 0
fi

mkdir -p "$cache_dir"
if [[ ! -f "$archive" ]]; then
    tmp="${archive}.part"
    rm -f "$tmp"
    curl --fail --location --proto '=https' --tlsv1.2 \
        --output "$tmp" "${FREERADIO_FFMPEG_URL}"
    mv "$tmp" "$archive"
fi

if command -v sha256sum >/dev/null 2>&1; then
    printf '%s  %s\n' "${FREERADIO_FFMPEG_SHA256}" "$archive" | sha256sum --check --status
else
    actual=$(shasum -a 256 "$archive" | cut -d' ' -f1)
    [[ "$actual" == "${FREERADIO_FFMPEG_SHA256}" ]]
fi

if [[ -e "$source_dir" && ! -f "$source_dir/configure" ]]; then
    printf 'Refusing to overwrite non-FFmpeg source directory: %s\n' "$source_dir" >&2
    exit 1
fi
if [[ ! -f "$source_dir/configure" ]]; then
    mkdir -p "$(dirname -- "$source_dir")"
    tar -xJf "$archive" -C "$(dirname -- "$source_dir")"
fi
printf '%s\n' "$source_dir"

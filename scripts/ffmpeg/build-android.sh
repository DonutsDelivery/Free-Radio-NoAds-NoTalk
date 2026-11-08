#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "${script_dir}/../.." && pwd)
# shellcheck source=configure-common.sh
source "${script_dir}/configure-common.sh"

usage() {
    printf 'Usage: %s --ndk DIR --abi arm64-v8a|x86_64 [--api 24] [--prefix DIR] [--source-dir DIR] [--build-dir DIR] [--jobs N] [--configure-only] [--dry-run]\n' "$0"
}

ndk="${ANDROID_NDK_ROOT:-${ANDROID_NDK_HOME:-}}"
abi=""
api=24
prefix=""
source_dir=""
build_dir=""
jobs=""
configure_only=0
dry_run=0
while (($#)); do
    case "$1" in
        --ndk) ndk=$2; shift 2 ;;
        --abi) abi=$2; shift 2 ;;
        --api) api=$2; shift 2 ;;
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
[[ -n "$ndk" && -n "$abi" ]] || { usage >&2; exit 2; }
[[ "$api" =~ ^[0-9]+$ ]] || { printf 'Android API must be numeric\n' >&2; exit 2; }
((api >= 24)) || { printf 'Android API 24 or newer is required\n' >&2; exit 2; }

case "$abi" in
    arm64-v8a) ffmpeg_arch=aarch64; clang_triple=aarch64-linux-android ;;
    x86_64) ffmpeg_arch=x86_64; clang_triple=x86_64-linux-android ;;
    *) printf 'Unsupported ABI: %s (expected arm64-v8a or x86_64)\n' "$abi" >&2; exit 2 ;;
esac
case "$(uname -s)-$(uname -m)" in
    Linux-*) host_tag=linux-x86_64 ;;
    Darwin-arm64) host_tag=darwin-arm64 ;;
    Darwin-x86_64) host_tag=darwin-x86_64 ;;
    *) printf 'Unsupported NDK build host: %s/%s\n' "$(uname -s)" "$(uname -m)" >&2; exit 1 ;;
esac

toolbin="${ndk}/toolchains/llvm/prebuilt/${host_tag}/bin"
sysroot="${ndk}/toolchains/llvm/prebuilt/${host_tag}/sysroot"
prefix=${prefix:-"${repo_dir}/build/ffmpeg/android/${abi}"}
source_dir=${source_dir:-"${repo_dir}/build/downloads/ffmpeg-${FREERADIO_FFMPEG_VERSION}"}
build_dir=${build_dir:-"${repo_dir}/build/ffmpeg-android-${abi}"}
if [[ -z "$jobs" ]]; then jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || printf 1); fi

flags=()
while IFS= read -r flag; do flags+=("$flag"); done < <(ffmpeg_common_flags)
command=("${source_dir}/configure"
    "--prefix=${prefix}"
    --target-os=android
    --enable-cross-compile
    "--arch=${ffmpeg_arch}"
    "--cc=${toolbin}/${clang_triple}${api}-clang"
    "--cxx=${toolbin}/${clang_triple}${api}-clang++"
    "--ar=${toolbin}/llvm-ar"
    "--nm=${toolbin}/llvm-nm"
    "--ranlib=${toolbin}/llvm-ranlib"
    "--strip=${toolbin}/llvm-strip"
    "--sysroot=${sysroot}"
    "${flags[@]}")
# FFmpeg's Android target installs an unversioned regular file and links with
# -Wl,-soname,$(SLIBNAME). Validate both properties after installation below.

if ((dry_run)); then
    printf 'License: LGPL-2.1-or-later\nABI: %s\nStaging: unversioned shared-library names and SONAMEs\n' "$abi"
    printf 'Configure:'; printf ' %q' "${command[@]}"; printf '\n'
    printf 'Build: make -C %q -j %q\n' "$build_dir" "$jobs"
    exit 0
fi
[[ -d "$ndk" ]] || { printf 'Android NDK not found: %s\n' "$ndk" >&2; exit 1; }
for tool in "${clang_triple}${api}-clang" llvm-ar llvm-nm llvm-ranlib llvm-strip llvm-readelf; do
    [[ -x "${toolbin}/${tool}" ]] || { printf 'Missing NDK tool: %s/%s\n' "$toolbin" "$tool" >&2; exit 1; }
done
if [[ ! -x "${source_dir}/configure" ]]; then
    source_dir=$("${script_dir}/fetch-ffmpeg.sh" --source-dir "$source_dir")
    command[0]="${source_dir}/configure"
fi
rm -rf "$build_dir" "$prefix"
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

for component in avformat avcodec avutil swresample; do
    library="${prefix}/lib/lib${component}.so"
    [[ -f "$library" && ! -L "$library" ]] || {
        printf 'Expected unversioned regular library was not staged: %s\n' "$library" >&2; exit 1;
    }
    soname=$("${toolbin}/llvm-readelf" -d "$library" | grep '(SONAME)' || true)
    [[ "$soname" == *"[lib${component}.so]"* ]] || {
        printf 'Unexpected SONAME for %s: %s\n' "$library" "$soname" >&2; exit 1;
    }
done
mkdir -p "${prefix}/compliance"
install -m 0644 "${source_dir}/COPYING.LGPLv2.1" "${prefix}/compliance/FFmpeg-LGPL-2.1-or-later.txt"
install -m 0644 "${repo_dir}/LICENSES/FFmpeg-NOTICE.txt" "${prefix}/compliance/FFmpeg-NOTICE.txt"
archive="$(dirname -- "$source_dir")/${FREERADIO_FFMPEG_ARCHIVE}"
if [[ -f "$archive" ]]; then
    install -m 0644 "$archive" "${prefix}/compliance/${FREERADIO_FFMPEG_ARCHIVE}"
else
    printf 'Pinned corresponding-source archive is missing: %s\n' "$archive" >&2
    exit 1
fi
ffmpeg_print_configuration > "${prefix}/compliance/configuration.txt"
printf 'Installed Android %s FFmpeg %s to %s\n' "$abi" "$FREERADIO_FFMPEG_VERSION" "$prefix"

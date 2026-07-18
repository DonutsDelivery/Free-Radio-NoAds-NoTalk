#!/usr/bin/env bash
set -euo pipefail

readonly OPENSSL_VERSION=3.0.21
readonly OPENSSL_ARCHIVE="openssl-${OPENSSL_VERSION}.tar.gz"
readonly OPENSSL_URL="https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/${OPENSSL_ARCHIVE}"
readonly OPENSSL_SHA256=617e29af8e421f46649484a4937e48c685e47f46488167c982f88bc4ec1d522f

usage() {
    cat <<'EOF'
Usage: build-android.sh --ndk DIR --prefix DIR [--abi arm64-v8a|x86_64] [--jobs N]

Builds pinned OpenSSL shared libraries with Qt Android's required _3 suffix.
When --abi is omitted, both supported ABIs are built.
EOF
}

ndk="${ANDROID_NDK_ROOT:-}"
prefix=""
abi=""
jobs="$(nproc)"
while (($#)); do
    case "$1" in
        --ndk) ndk="$2"; shift 2 ;;
        --prefix) prefix="$2"; shift 2 ;;
        --abi) abi="$2"; shift 2 ;;
        --jobs) jobs="$2"; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

[[ -d "$ndk" ]] || { printf 'Android NDK not found: %s\n' "$ndk" >&2; exit 2; }
[[ -n "$prefix" ]] || { printf '%s\n' '--prefix is required' >&2; exit 2; }
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || { printf '%s\n' '--jobs must be a positive integer' >&2; exit 2; }

if [[ -n "$abi" ]]; then
    abis=("$abi")
else
    abis=(arm64-v8a x86_64)
fi

cache="${XDG_CACHE_HOME:-$HOME/.cache}/freeradio"
archive="$cache/$OPENSSL_ARCHIVE"
mkdir -p "$cache" "$prefix"
prefix="$(cd "$prefix" && pwd)"
if [[ ! -f "$archive" ]] || ! printf '%s  %s\n' "$OPENSSL_SHA256" "$archive" | sha256sum --check --status; then
    rm -f "$archive"
    curl --fail --location --retry 3 --output "$archive" "$OPENSSL_URL"
fi
printf '%s  %s\n' "$OPENSSL_SHA256" "$archive" | sha256sum --check --status

case "$(uname -s)" in
    Linux) host_tag=linux-x86_64 ;;
    Darwin) host_tag=darwin-x86_64 ;;
    *) printf 'Unsupported build host: %s\n' "$(uname -s)" >&2; exit 2 ;;
esac
toolchain="$ndk/toolchains/llvm/prebuilt/$host_tag/bin"
[[ -d "$toolchain" ]] || { printf 'NDK LLVM toolchain not found: %s\n' "$toolchain" >&2; exit 2; }
export ANDROID_NDK_ROOT="$ndk"
export PATH="$toolchain:$PATH"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
for current_abi in "${abis[@]}"; do
    case "$current_abi" in
        arm64-v8a) openssl_arch=arm64 ;;
        x86_64) openssl_arch=x86_64 ;;
        *) printf 'Unsupported Android ABI: %s\n' "$current_abi" >&2; exit 2 ;;
    esac

    build_dir="$prefix/.build-$current_abi"
    output_dir="$prefix/$current_abi"
    rm -rf "$build_dir" "$output_dir"
    mkdir -p "$build_dir" "$output_dir"
    tar -xzf "$archive" -C "$build_dir" --strip-components=1
    patch -d "$build_dir" -p0 < "$script_dir/qt-android-openssl-3.patch"
    (
        cd "$build_dir"
        ./Configure "android-$openssl_arch" shared no-tests \
            -U__ANDROID_API__ -D__ANDROID_API__=26 \
            -Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384
        make -j"$jobs" SHLIB_VERSION_NUMBER= build_libs
        llvm-strip --strip-all libcrypto_3.so libssl_3.so
        cp libcrypto_3.so libssl_3.so "$output_dir/"
    )
    cp "$script_dir/../../LICENSES/OpenSSL-Apache-2.0.txt" "$output_dir/"
    printf 'OpenSSL %s\nSource: %s\nSHA-256: %s\n' \
        "$OPENSSL_VERSION" "$OPENSSL_URL" "$OPENSSL_SHA256" > "$output_dir/BUILD-INFO.txt"
    rm -rf "$build_dir"
    printf 'Built OpenSSL %s for %s in %s\n' "$OPENSSL_VERSION" "$current_abi" "$output_dir"
done

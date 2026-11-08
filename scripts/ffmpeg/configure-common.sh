#!/usr/bin/env bash
# Shared, LGPL-only feature set for every Free Radio FFmpeg build.
# Source this file, then append the printed flags to FFmpeg's configure command.
set -euo pipefail

readonly FREERADIO_FFMPEG_VERSION=8.0.3
readonly FREERADIO_FFMPEG_ARCHIVE="ffmpeg-${FREERADIO_FFMPEG_VERSION}.tar.xz"
readonly FREERADIO_FFMPEG_URL="https://ffmpeg.org/releases/${FREERADIO_FFMPEG_ARCHIVE}"
readonly FREERADIO_FFMPEG_SHA256=6136812ea6d4e68bdba27e33c2a94382711cdf4f8602ffef056ff792bd6f9818

ffmpeg_common_flags() {
    printf '%s\n' \
        --disable-everything \
        --disable-autodetect \
        --disable-programs \
        --disable-doc \
        --disable-debug \
        --disable-static \
        --enable-shared \
        --disable-avdevice \
        --disable-avfilter \
        --disable-swscale \
        --enable-avcodec \
        --enable-avformat \
        --enable-avutil \
        --enable-swresample \
        --disable-network \
        --enable-pthreads \
        --disable-iconv \
        --disable-bzlib \
        --disable-lzma \
        --disable-zlib \
        --disable-gpl \
        --disable-nonfree \
        --disable-version3 \
        --enable-small \
        --enable-protocol=file,pipe \
        --enable-demuxer=aac,asf,flac,hls,mov,mp3,ogg,wav \
        --enable-parser=aac,aac_latm,flac,mpegaudio,opus \
        --enable-decoder=aac,aac_fixed,flac,mp3,mp3float,opus,vorbis,pcm_s16le,pcm_s24le,pcm_s32le,pcm_f32le,wmav1,wmav2,wmapro,wmalossless
}

ffmpeg_print_configuration() {
    printf 'Free Radio FFmpeg %s (LGPL-2.1-or-later; GPL, nonfree, and version-3 components disabled)\n' \
        "${FREERADIO_FFMPEG_VERSION}"
    ffmpeg_common_flags
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    ffmpeg_print_configuration
fi

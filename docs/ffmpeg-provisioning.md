# FFmpeg provisioning

Free Radio accepts exactly FFmpeg 8.0.3. Application configuration never downloads it and never falls back to a different provider.

## Native desktop

Install matching FFmpeg development packages and configure with the default strict pkg-config provider:

```sh
cmake -S freeradio -B build/native \
  -DFREERADIO_FFMPEG_PROVIDER=PKGCONFIG
cmake --build build/native
ctest --test-dir build/native --output-on-failure
```

To create the pinned minimal shared build instead:

```sh
scripts/ffmpeg/build-native.sh --prefix "$PWD/build/ffmpeg/native"
cmake -S freeradio -B build/native \
  -DFREERADIO_FFMPEG_PROVIDER=EXPLICIT \
  -DFREERADIO_FFMPEG_INCLUDE_DIR="$PWD/build/ffmpeg/native/include" \
  -DFREERADIO_AVFORMAT_LIBRARY="$PWD/build/ffmpeg/native/lib/libavformat.so" \
  -DFREERADIO_AVCODEC_LIBRARY="$PWD/build/ffmpeg/native/lib/libavcodec.so" \
  -DFREERADIO_AVUTIL_LIBRARY="$PWD/build/ffmpeg/native/lib/libavutil.so" \
  -DFREERADIO_SWRESAMPLE_LIBRARY="$PWD/build/ffmpeg/native/lib/libswresample.so"
```

Use the platform's shared-library suffix on macOS or Windows. The explicit provider requires absolute existing paths.

## Android

Set `ANDROID_NDK_ROOT` to Android NDK r25b, then build both supported FFmpeg ABIs and the pinned OpenSSL 3.0.21 TLS runtime:

```sh
scripts/ffmpeg/build-android.sh --ndk "$ANDROID_NDK_ROOT" --abi arm64-v8a
scripts/ffmpeg/build-android.sh --ndk "$ANDROID_NDK_ROOT" --abi x86_64
scripts/openssl/build-android.sh \
  --ndk "$ANDROID_NDK_ROOT" \
  --prefix "$PWD/build/openssl/android"
```

Qt 6.6 dynamically loads `libcrypto_3.so` and `libssl_3.so` on Android. Free Radio fails configuration when these libraries are absent because almost all catalog streams require HTTPS; silently producing an APK without a functional TLS backend would make playback fail at runtime.

Configure the Qt Android application with the staged ABI matching `CMAKE_ANDROID_ARCH_ABI`:

```sh
abi=arm64-v8a
prefix="$PWD/build/ffmpeg/android/$abi"
cmake -S freeradio -B "build/android-$abi" \
  -DQT_HOST_PATH="$QT_HOST_PATH" \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI="$abi" -DANDROID_PLATFORM=android-26 \
  -DFREERADIO_ANDROID_OPENSSL_ROOT="$PWD/build/openssl/android" \
  -DFREERADIO_FFMPEG_PROVIDER=EXPLICIT \
  -DFREERADIO_FFMPEG_INCLUDE_DIR="$prefix/include" \
  -DFREERADIO_AVFORMAT_LIBRARY="$prefix/lib/libavformat.so" \
  -DFREERADIO_AVCODEC_LIBRARY="$prefix/lib/libavcodec.so" \
  -DFREERADIO_AVUTIL_LIBRARY="$prefix/lib/libavutil.so" \
  -DFREERADIO_SWRESAMPLE_LIBRARY="$prefix/lib/libswresample.so"
cmake --build "build/android-$abi"
```

The Android script stages regular unversioned `.so` files with unversioned SONAMEs. This allows Qt's Android deployment tooling to discover and package them. CMake rejects Android pkg-config and versioned explicit filenames to prevent host or incompatible libraries from entering an APK.

## Validation and compliance

All scripts support `--help`; fetch and build scripts support `--dry-run`. `configure-common.sh` prints the exact LGPL-only feature set. The build enables only the demuxers and audio decoders used by the in-process streaming engine and explicitly disables GPL, nonfree, and LGPLv3 components.

Android staging includes the FFmpeg license, notice, configuration, and pinned corresponding-source archive under `compliance/`. Packaging must include these materials in the distributed artifact or alongside it in the same release. Do not enable additional external libraries without reviewing their licenses and updating the notice and source bundle.

# Platform Build and Acceptance

This guide is the operational source of truth for Free Radio desktop artifacts and native runtime acceptance.

## Ownership and support state

Release files are built locally, the same way as DonutStudio and DonutMediaCenter. GitHub Actions does not run on this account, and `.github/workflows/build.yml` is now a manual diagnostic that never publishes.

| Platform | Command (from a clean checkout) | Output in `dist/` | Where it compiles |
|---|---|---|---|
| Linux | `packaging/local/build-linux.sh` | `DonutRadio-Linux-x86_64.AppImage`, `donutradio.plasmoid` | Ubuntu 22.04 Docker image, Linux build token |
| Windows | `packaging/local/build-windows.sh` | `DonutRadio-Windows-Portable-x64.zip`, `DonutRadio-Setup-x64.exe` | DonutStudio's msvc-wine and Inno images, Linux build token |
| macOS | `packaging/local/build-macos.sh` | `DonutRadio-macOS.dmg` (arm64, ad-hoc signed) | The physical MacBook over SSH, its `/tmp/arbit-build.lock` |

- Toolchain pins live in `packaging/local/versions.env`: Qt 6.7.0, KF/Kirigami 6.3.0 and the aqtinstall version. FFmpeg is pinned to 8.0.3 by `scripts/ffmpeg/configure-common.sh`.
- Each wrapper refuses a dirty tree, builds from an exported copy of `HEAD`, smoke-starts the packaged app and writes `dist/<platform>-receipt.txt` with the commit and SHA-256 of every file.
- Set `HOST_HEAVY_BUILD_WAIT_SECONDS=21600` to queue for the Linux token instead of failing when another project holds it. Dependency trees (Kirigami, FFmpeg) are cached under `~/.cache/donutradio-release/` on Linux and `~/build/donutradio-release/` on the Mac, so only the app recompiles on later runs.
- WinBoat is runtime acceptance only; never compile or package DonutRadio there.
- The Sonoma VM is the local x86_64 native compile and functional-test worker. It cannot establish Apple Silicon, notarization, representative GPU, or real CoreAudio latency support.
- The shared DonutsDelivery profile excludes macOS from stable support until the exact shipping artifact passes real Apple-hardware audio, network playback, and sustained-use acceptance.

## Exact source and receipts

Freeze one clean full source commit. Record the commit, catalog hash, FFmpeg source/version/hash and configure receipt, Qt/KF/CMake/Ninja versions, architecture, app/DMG hashes, signature/notarization state, and CI/native-builder logs. Free Radio requires the pinned FFmpeg 8.0.3 ABI; a bundle that silently resolves another host FFmpeg is invalid.

## Native macOS build

Use `/home/user/VMs/donutstudio-macos-builder` as the configured Sonoma worker. Stage an exact SHA-named source snapshot and provision the same versions used by `.github/workflows/build.yml`: Qt 6.7.0 with multimedia/shadertools, KF/Kirigami 6.3.0, CMake, Ninja, ImageMagick, and the pinned Free Radio FFmpeg runtime.

The canonical configure/build sequence is:

```bash
cmake -B build -S freeradio -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$Qt6_DIR;$HOME/kde"
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

Then mirror the workflow packaging steps: form `Free Radio.app`, install the tracked `Info.plist` and icon, run `macdeployqt` with both the application QML directory and custom Kirigami import root, deep ad-hoc sign after deployment, verify the signature, launch the actual bundled executable, and create/verify `FreeRadio-macOS.dmg` with `hdiutil`. Do not ignore `macdeployqt`, DMG, codesign, or launch failures as the current helper/workflow sometimes does; an ignored failure cannot produce an accepted candidate.

Install by mounting the exact DMG and copying the app to `/Users/builder/Applications`. Record bundle version/identifier, executable architecture, linked Qt/KF/FFmpeg libraries, signature state, process path, and host/guest SHA-256. An x86_64 VM result must not be labeled universal or Apple Silicon.

## Sonoma VM lifecycle

```bash
cd /home/user/VMs/donutstudio-macos-builder
docker ps -a --filter name=donutstudio-macos-builder
./launch.sh
./wait-for-ssh.sh 240
gvncviewer --zoom=70 127.0.0.1:0
./ssh-macos.sh 'sw_vers; uptime'
```

Do not start a duplicate. The operator signs in; agents never enter credentials. Before restart, inspect active guest compilers and preserve evidence. The VM may be restarted without asking, but not through an active compile/link.

```bash
cd /home/user/VMs/donutstudio-macos-builder
./shutdown-macos.sh
# Wait for launcher/container exit before ./launch.sh again.
```

Use Recovery only for diagnosed recovery work. Never force-kill while SSH shutdown works.

## WinBoat lifecycle

```bash
docker compose -f /home/user/.winboat/docker-compose.yml ps
docker compose -f /home/user/.winboat/docker-compose.yml up -d windows
```

Sign in interactively and install/extract the exact Windows CI candidate in an isolated SHA/hash-specific location. Never rebuild in WinBoat. Stop through Windows **Power → Shut down**; bounded fallback:

```bash
docker compose -f /home/user/.winboat/docker-compose.yml stop --timeout 120 windows
docker compose -f /home/user/.winboat/docker-compose.yml ps
```

Never `docker kill`, recreate the compose project, or delete `/home/user/winboat` for a routine restart.

## End-to-end acceptance matrix

Run every applicable row against the exact installed candidate:

1. **Install/identity** — DMG or Windows installer/portable package opens, installs, launches, and reports the expected version/source; process path and hashes match the candidate.
2. **Bundle dependencies** — Qt, Kirigami QML, FreeRadio.Audio plugin, pinned FFmpeg libraries, platform plugins, TLS/network plugins, and codecs resolve from intended package paths rather than accidental build/host paths.
3. **Catalog and station selection** — canonical catalog validation passes; browse/search/filter, favorites, recent/history, country/genre metadata, and restart persistence work.
4. **Network playback** — HTTP/HTTPS streams, redirects, playlists, ICY metadata, reconnect/backoff, stalled/broken stations, DNS loss, network loss/restore, and station switching behave without hangs or leaked decoders.
5. **Audio output** — CoreAudio on Sonoma and Windows audio on WinBoat enumerate; play/pause/stop, volume/mute, device loss/reopen, sample conversion, long playback, and clipping/non-silence meters pass. VM audio proves function only, not hardware latency or fidelity.
6. **FFmpeg engine** — exact ABI is loaded; codec/container coverage, buffer pressure, malformed input, cancellation, and repeated station changes do not crash or leak threads.
7. **Desktop integration** — media keys/session controls, notifications, tray/taskbar/menu behavior, window restoration, shortcuts, and quit semantics work where supported.
8. **Windowing/rendering** — complete UI at 1920x1080 and a smaller workspace, no unreachable dialogs, correct QML/Kirigami rendering, and acceptable software-framebuffer behavior.
9. **Packaging/security** — Gatekeeper/SmartScreen, quarantine, signature/notarization state, installer replacement, uninstall, update metadata, and failure rollback are recorded honestly.
10. **Sustained use** — hours-scale playback and repeated reconnect/station switching show stable CPU/memory/thread/socket counts and recover after app/guest restart.

Save catalog/toolchain receipts, linked-library output, audio/network logs, inspected screenshots, artifact hashes, and cleanup results separately. Stable macOS support requires the exact shipping DMG on real Apple Silicon and any claimed Intel hardware with real CoreAudio devices, sleep/wake, network transitions, signing/notarization, and sustained playback.

---
name: verify-free-radio-gui
description: Build and drive the Free Radio Qt/QML desktop app on an isolated X11 display.
---

# Verify Free Radio GUI

1. Configure a fresh build directory so stale absolute paths in `freeradio/build/` do not interfere:
   ```bash
   cmake -S freeradio -B freeradio/build-verify -G Ninja -DCMAKE_BUILD_TYPE=Debug
   cmake --build freeradio/build-verify
   ```
2. Start an isolated display: `Xvfb :99 -screen 0 1280x800x24 -nolisten tcp`.
3. Copy the executable to a unique `/tmp` name before launching so the project-required `pgrep freeradio` restart command from another worker cannot terminate the verification process.
4. Launch with:
   ```bash
   DISPLAY=:99 QT_QPA_PLATFORM=xcb QT_QUICK_BACKEND=software \
     XDG_CONFIG_HOME=/tmp/freeradio-verify-config /tmp/freeradio-verify-bin
   ```
5. Find the input/output window with `DISPLAY=:99 xwininfo -root -tree`; ignore the 10x10 `InputOnly` helper.
6. Drive the 400x650 window with `xdotool`, then capture it using `xwd` and convert with ImageMagick. Verify at least source list → provider categories → station list, plus an empty-data navigation path.
7. Inspect the app process output for QML errors and stop the isolated app/Xvfb when finished.

The normal project post-change restart and installed-QML copy requirements still apply outside this isolated verification handle.

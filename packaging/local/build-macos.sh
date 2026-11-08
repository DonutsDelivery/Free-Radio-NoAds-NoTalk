#!/usr/bin/env bash
# Build the macOS DMG on the physical Apple Silicon MacBook, from Linux, no CI:
#   dist/DonutRadio-macOS.dmg (arm64, ad-hoc signed, not notarized)
# Stages the committed tree over SSH, builds under the Mac's /tmp/arbit-build.lock (never
# the Linux token) and copies the DMG back.
# Usage: packaging/local/build-macos.sh   (MAC=user@host overrides the target)
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
require_clean_tree
MAC="${MAC:-emilankerstjerne@192.168.0.243}"
WORK="build/donutradio-release/work-$SOURCE_COMMIT"
SSH=(ssh -A -o BatchMode=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=6 "$MAC")

"${SSH[@]}" "rm -rf ~/$WORK && mkdir -p ~/$WORK/src"
git -C "$REPO" archive --format=tar HEAD | "${SSH[@]}" "tar -xf - -C ~/$WORK/src"
"${SSH[@]}" "JOBS=${JOBS:-3} bash ~/$WORK/src/packaging/local/macos-on-mac.sh ~/$WORK"
mkdir -p "$DIST"
scp -o BatchMode=yes "$MAC:$WORK/DonutRadio-macOS.dmg" "$DIST/DonutRadio-macOS.dmg"
write_receipt macos-receipt.txt DonutRadio-macOS.dmg
cat "$DIST/macos-receipt.txt"

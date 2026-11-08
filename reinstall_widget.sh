#!/bin/bash

WIDGET_ID="online.donutsdelivery.donutradio"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting widget reinstallation..."

# Kill all plasma processes
echo "Stopping Plasma..."
kquitapp6 plasmashell
pkill -f krunner
sleep 3

# Remove widget and clear all caches
echo "Removing old widget..."
# Also remove the ids this widget shipped under before the rename.
for old_id in "$WIDGET_ID" freeradio radcapradio; do
    kpackagetool6 --type="Plasma/Applet" --remove "$old_id" 2>/dev/null || true
    rm -rf ~/.local/share/plasma/plasmoids/"$old_id"
done
rm -rf ~/.cache/plasmashell
rm -rf ~/.cache/plasma-qmlcache
rm -rf ~/.cache/plasma*
rm -rf ~/.cache/kservice*

# Rebuild KDE system cache
kbuildsycoca6 --noincremental

# Wait for filesystem sync
sync
sleep 2

# Install widget fresh
echo "Installing widget..."
kpackagetool6 --type="Plasma/Applet" --upgrade "$REPO_DIR/freeradio"

# Wait and restart plasma
echo "Restarting Plasma..."
sleep 3
kstart plasmashell
sleep 5

echo "Widget reinstallation complete!"
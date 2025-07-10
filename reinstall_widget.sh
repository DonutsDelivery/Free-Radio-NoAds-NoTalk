#!/bin/bash

echo "Starting widget reinstallation..."

# Kill all plasma processes
echo "Stopping Plasma..."
kquitapp5 plasmashell
pkill -f krunner
sleep 3

# Remove widget and clear all caches
echo "Removing old widget..."
kpackagetool6 --type="Plasma/Applet" --remove radcapradio 2>/dev/null || true
rm -rf ~/.local/share/plasma/plasmoids/radcapradio
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
cd /home/user/Documents/Free-Radio-NoAds-NoTalk
kpackagetool6 --type="Plasma/Applet" --upgrade radcapradio

# Wait and restart plasma
echo "Restarting Plasma..."
sleep 3
kstart5 plasmashell
sleep 5

echo "Widget reinstallation complete!"
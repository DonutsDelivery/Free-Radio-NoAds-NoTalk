# FreeRadio Widget Reinstall Instructions

## Critical Information for Future Sessions

### Plasma Version & Location
- **Plasma Version**: 6.4.2
- **Correct Install Location**: `~/.local/share/plasma/plasmoids/freeradio/`
- **Wrong Location** (old method): `~/.local/share/kpackage/generic/freeradio/`

### Current Widget Status
- **Main Spectrum Component**: `SpectrumVisualizerNew` (in main.qml line 5215) - WORKING v4.0
- **Current Worker**: `SpectrumWorkerFFT.js` v3.0 (balanced uniform frequency bands)
- **Advanced Components**: `SpectrumVisualizerAdvanced.qml` and `SpectrumWorkerAdvanced.js` (available but not active)

### Proper Reinstall Process

#### 1. Copy Updated Files to Plasma 6 Location
```bash
# Navigate to project
cd /home/user/Documents/Free-Radio-NoAds-NoTalk/freeradio

# Copy all updated files to correct Plasma 6 location
cp contents/ui/main.qml ~/.local/share/plasma/plasmoids/freeradio/contents/ui/
cp contents/ui/SpectrumVisualizerAdvanced.qml ~/.local/share/plasma/plasmoids/freeradio/contents/ui/
cp contents/ui/SpectrumWorkerAdvanced.js ~/.local/share/plasma/plasmoids/freeradio/contents/ui/
cp contents/ui/SpectrumVisualizerNew.qml ~/.local/share/plasma/plasmoids/freeradio/contents/ui/
cp contents/ui/SpectrumWorkerFFT.js ~/.local/share/plasma/plasmoids/freeradio/contents/ui/
```

#### 2. Restart Plasma Shell
```bash
# Method 1: Graceful restart
kquitapp5 plasmashell
sleep 3
kstart5 plasmashell

# Method 2: Force restart if needed
killall plasmashell
sleep 3
plasmashell > /dev/null 2>&1 &
```

#### 3. Verify Installation
```bash
# Check version in logs (should show advanced versions)
journalctl --user --since="2 minutes ago" | grep -E "(SpectrumVisualizerAdvanced|SpectrumWorkerAdvanced)"

# Check installed files
ls -la ~/.local/share/plasma/plasmoids/freeradio/contents/ui/Spectrum*

# Verify correct component in main.qml
grep -n "SpectrumVisualizerAdvanced" ~/.local/share/plasma/plasmoids/freeradio/contents/ui/main.qml
```

### Expected Log Output After Restart
```
SpectrumVisualizerAdvanced v1.0 - High-performance FFT with configurable scaling
SpectrumWorkerAdvanced v1.0 - High-performance FFT with audioMotion features
```

### Advanced Features Available
- **Interactive Controls**: Click to cycle frequency scales (Linear/Log/Bark/Mel)
- **Configuration**: Double-click to toggle frequency labels and FPS display
- **Performance**: High-performance fft.js with 35k+ ops/sec
- **Visual**: Enhanced gradients, peak indicators, smoothing algorithms

### Troubleshooting

#### If Widget Doesn't Update
1. Clear plasma cache: `rm -rf ~/.cache/plasma* ~/.cache/plasmashell`
2. Force reinstall: Remove and reinstall widget completely
3. Check file permissions and timestamps

#### If Logs Show Old Versions
- Plasma may be caching - do complete restart cycle
- Verify files are actually copied to correct location
- Check for typos in component names

### Development Notes
- **Main Component**: Line 5215 in main.qml uses `SpectrumVisualizerAdvanced`
- **FFT Library**: fft.js integrated directly in worker for performance
- **Frequency Scales**: Linear(0), Log(1), Bark(2), Mel(3)
- **Performance**: 60 FPS with real-time monitoring

### Quick Commands for Future Sessions
```bash
# Full reinstall sequence
cd /home/user/Documents/Free-Radio-NoAds-NoTalk/freeradio
cp contents/ui/*.qml contents/ui/*.js ~/.local/share/plasma/plasmoids/freeradio/contents/ui/
killall plasmashell && sleep 3 && plasmashell > /dev/null 2>&1 &
sleep 10 && journalctl --user --since="1 minute ago" | grep -E "SpectrumVisualizer.*v[0-9]"
```

---
**Last Updated**: Session with widget upgrade to SpectrumVisualizerAdvanced
**Files Modified**: main.qml, SpectrumVisualizerAdvanced.qml, SpectrumWorkerAdvanced.js
**Plasma Version**: 6.4.2 confirmed working
# Free Radio - Changelog

## Version 1.5.6 - July 2025

### 🎵 Major Audio Features

#### **Custom Audio Processing Pipeline**
- **Native Audio Engine**: Implemented custom C++ AudioEngine using miniaudio library
- **Direct Audio Stream Processing**: Bypasses Qt MediaPlayer for better audio control and spectrum analysis
- **FFT-Based Audio Analysis**: Real-time Fast Fourier Transform for spectrum visualization
- **High-Performance Audio**: Low-latency audio processing with customizable buffer sizes

#### **Spectrum Visualizer Implementation**
- **Multiple Visualizer Components**: 
  - `SpectrumVisualizer.qml` - Standard audio reactive bars
  - `SpectrumVisualizerAdvanced.qml` - Enhanced visualization with peak detection
  - `SystemAudioCapture.qml` - System audio monitoring capabilities
- **Real-Time Audio Analysis**: Live spectrum analysis with configurable sensitivity and decay rates
- **Visual Audio Response**: Audio-reactive animations synchronized with playback
- **Performance Optimized**: Efficient rendering with customizable bar count and smoothing

#### **Audio Worker System**
- **SpectrumWorker.js**: Core audio processing logic with FFT calculations
- **SpectrumWorkerAdvanced.js**: Advanced audio analysis with peak detection and frequency band separation
- **fft.js**: JavaScript-based Fast Fourier Transform implementation for real-time audio analysis

#### **Minimal Player Component**
- **MinimalPlayer.qml**: Lightweight MediaPlayer wrapper for consistent audio handling
- **Reduced Complexity**: Simplified audio playback without conflicting event handlers
- **Better Stability**: Prevents audio loop issues and improves reliability

### 🔧 Technical Enhancements
- **CMake Build System**: Updated build configuration for plugin architecture
- **Plugin Architecture**: Modular audio engine as Qt plugin for better integration
- **AUR Package Updates**: Updated Arch Linux package for plasma6 compatibility
- **Build Improvements**: Enhanced CMake configuration for audio engine compilation

### 📦 Package Management
- **Version Bump**: Updated to 1.5.6 in PKGBUILD and metadata
- **Plasma 6 Compatibility**: Ensured compatibility with latest KDE Plasma 6
- **Audio Dependencies**: Added miniaudio library integration for enhanced audio processing

---

## Version 1.2.1 - December 2024

### 🔧 Bug Fixes

#### **Fixed Next/Previous Station Navigation**
- **Context-Independent Navigation**: Next/Previous buttons now work from any screen (main menu, categories, search, etc.)
- **Comprehensive Station Pool**: Navigation uses all available stations from RadCap, SomaFM, custom stations, and favorites
- **Smart Station Finding**: Accurately locates current station in complete database
- **Circular Navigation**: Wraps around from last to first station and vice versa
- **Proper State Management**: Maintains station information and saves last played station

---

## Version 1.2.0 - December 2024

### 🎉 Major Features

#### **Multi-Source Radio Discovery**
- **Integrated Icecast Directory**: Browse thousands of live radio stations from the global Icecast directory
- **RadCap Curated Channels**: Access high-quality, ad-free music channels across multiple genres
- **SomaFM Integration**: Stream popular commercial-free stations from SomaFM

#### **Advanced Search & Discovery**
- **Live Station Search**: Search through 10,000+ radio stations in real-time
- **Smart Filtering**: Filter by bitrate, codec, and quality to find exactly what you want
- **Genre-Based Browsing**: Explore stations by music genres and categories
- **Preview Playback**: Test stations before committing to full playback

#### **Custom Station Management**
- **Add Your Own URLs**: Input custom radio stream URLs for your personal stations
- **M3U Playlist Support**: Add entire playlists by pasting M3U URLs
- **Station Editing**: Modify and manage your custom station collection
- **Persistent Storage**: All custom stations saved across widget restarts

#### **Smart Playback Controls**
- **Automatic Quality Selection**: Always streams at highest available quality
- **Last Station Memory**: Remembers and restores your last played station
- **Integrated Volume Control**: Volume slider and mute button in the main control row
- **Navigation Controls**: Previous/Next station, Random station discovery

#### **Live Metadata Display**
- **Real-Time Song Info**: Shows currently playing song title and artist when available
- **Stream Details**: Displays bitrate, channels, and technical stream information
- **Visual Stream URL**: See the actual stream URL to verify quality and source

### 🛠️ User Interface Improvements
- **Streamlined Layout**: Removed redundant quality selector for cleaner design
- **Responsive Design**: Adapts to different widget sizes automatically
- **Favorites System**: Save and organize your preferred stations
- **Modern Kirigami Styling**: Native KDE Plasma 6 look and feel

### 🔧 Technical Enhancements
- **RadCap URL Optimization**: Fixed quality port switching for RadCap channels
- **Improved Error Handling**: Better handling of unavailable or broken streams
- **Metadata Caching**: Efficient metadata fetching and display
- **Multi-threaded Search**: Non-blocking search operations

---

## Installation

```bash
kpackagetool5 --install freeradio
```

Add "Free Radio" from your KDE Plasma widget list.

## Key Features Summary

✅ **10,000+ Radio Stations** - Icecast directory integration  
✅ **Custom URL Support** - Add your own radio streams  
✅ **M3U Playlist Import** - Import entire station lists  
✅ **Real-time Search** - Find stations instantly  
✅ **Quality Filtering** - Filter by bitrate and codec  
✅ **Live Metadata** - See current song information  
✅ **Favorites System** - Save preferred stations  
✅ **Station Memory** - Remembers last played station  
✅ **Preview Mode** - Test before playing  
✅ **No Ads/Talk** - Curated high-quality music streams  

Perfect for music lovers who want access to global radio without ads, talk shows, or interruptions.
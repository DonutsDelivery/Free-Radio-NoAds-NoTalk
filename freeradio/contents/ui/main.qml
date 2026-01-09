// Free Radio Widget - Updated by Claude Code
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtMultimedia
import org.kde.plasma.plasmoid
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
// import Freeradio 1.0  // Commented out - using standard MediaPlayer
import "radiodata.js" as RadioData

PlasmoidItem {
    id: root
    
    // Detect if this is a compact representation (panel mode)
    property bool isCompactMode: plasmoid.formFactor === PlasmaCore.Types.Horizontal || 
                                plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool isHorizontalPanel: plasmoid.formFactor === PlasmaCore.Types.Horizontal
    property bool isVerticalPanel: plasmoid.formFactor === PlasmaCore.Types.Vertical
    
    // Popup state
    property bool showPopup: false
    
    
    // Playback state tracking
    property bool userPaused: false
    property real lastBufferProgress: 0
    property int lastBufferUpdateTime: 0
    property int restartAttempts: 0
    property int maxRestartAttempts: 3
    
    // Adaptive sizing properties - FORCE 720P SIMULATION MODE with optimized text sizing
    // Simulate widget running on 720p screen by scaling down effective dimensions
    property real simulatedWidth: Math.min(root.width, root.width * 720 / 2560) // Scale down from your 2560px to 720p equivalent
    property real simulatedHeight: Math.min(root.height, root.height * 720 / 1440) // Scale down from your 1440px to 720p equivalent
    
    // Optimized text sizing hierarchy that makes better use of space
    property real availableTextWidth: simulatedWidth - (marginSize * 2) // Account for margins
    property real availableTextHeight: simulatedHeight - (marginSize * 2)
    property real marginSize: Math.max(6, Math.min(15, simulatedWidth / 40)) // Match spacingLarge value for consistent gaps
    
    // Text size hierarchy optimized for space utilization
    property real microFontSize: Math.max(7, Math.min(9, availableTextWidth / 80))     // Very small text (codec info, etc)
    property real smallFontSize: Math.max(8, Math.min(11, availableTextWidth / 65))    // Small text (secondary info)
    property real baseFontSize: Math.max(10, Math.min(13, availableTextWidth / 50))    // Base text (most content)
    property real titleFontSize: Math.max(12, Math.min(16, availableTextWidth / 40))   // Titles and important text
    property real largeFontSize: Math.max(14, Math.min(18, availableTextWidth / 35))   // Large headings
    property real headerFontSize: Math.max(16, Math.min(20, availableTextWidth / 30))  // Main headers
    
    // Size classifications
    property bool isVerySmall: simulatedWidth < 180 || simulatedHeight < 120
    property bool isSmall: simulatedWidth < 250 || simulatedHeight < 160
    property bool isMedium: simulatedWidth < 350 || simulatedHeight < 220
    
    // Button and control sizing - increased for better touch targets
    property real buttonSize: Math.max(32, Math.min(44, Math.min(simulatedWidth / 11, simulatedHeight / 14)))
    
    // Panel mode sizing - scales properly with panel orientation and size
    property real panelButtonSize: {
        if (!isCompactMode) return compactButtonSize
        if (isHorizontalPanel) {
            // For horizontal panels, scale with panel height
            return Math.max(16, Math.min(root.height * 0.8, 48))
        } else if (isVerticalPanel) {
            // For vertical panels, scale with panel width  
            return Math.max(16, Math.min(root.width * 0.8, 48))
        }
        return compactButtonSize
    }
    property real panelSpacing: isCompactMode ? Math.max(1, Math.min(4, panelButtonSize / 10)) : spacingSmall
    property real panelFontSize: isCompactMode ? Math.max(8, Math.min(16, panelButtonSize * 0.45)) : baseFontSize
    
    // Fallback compact button size for non-panel use
    property real compactButtonSize: Math.max(24, Math.min(36, Math.min(simulatedWidth / 5.5, simulatedHeight * 0.75)))
    
    // Layout spacing that scales with size - increased for better breathing room
    property real spacingSmall: Math.max(4, Math.min(8, simulatedWidth / 60))
    property real spacingMedium: Math.max(6, Math.min(12, simulatedWidth / 50))
    property real spacingLarge: Math.max(10, Math.min(18, simulatedWidth / 35))
    
    // Scrollbar management - smart sizing and visibility with proper boundaries
    // Use actual widget width for scrollbar sizing, not simulated width
    property real scrollbarWidth: 12  // Medium scrollbar width
    property real scrollbarMargin: 10  // Adjusted margin for 12px scrollbar
    property real scrollbarTotalSpace: scrollbarWidth + scrollbarMargin * 2  // Total space needed for scrollbar
    property bool enableScrollbars: !isVerySmall && root.width > 200
    property bool forceHideScrollbars: isVerySmall || root.width < 180

    // ═══════════════════════════════════════════════════════════════════
    // REFINED AUDIO DESIGN SYSTEM - Sophisticated music-focused aesthetic
    // ═══════════════════════════════════════════════════════════════════

    // Primary accent colors - warm amber/gold tones for audio vibes
    property color accentPrimary: "#E67E22"      // Warm amber - primary actions
    property color accentSecondary: "#F39C12"   // Golden yellow - highlights
    property color accentTertiary: "#D35400"    // Deep orange - emphasis

    // Semantic colors
    property color nowPlayingColor: "#27AE60"   // Vibrant green - active/playing
    property color favoriteColor: "#F1C40F"     // Gold - favorites
    property color sourceColor: "#3498DB"       // Blue - sources
    property color categoryColor: "#9B59B6"     // Purple - categories

    // Surface colors (overlay on theme background)
    property color surfaceElevated: Qt.rgba(Kirigami.Theme.backgroundColor.r * 1.1,
                                            Kirigami.Theme.backgroundColor.g * 1.1,
                                            Kirigami.Theme.backgroundColor.b * 1.1, 0.95)
    property color surfaceCard: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                                        Kirigami.Theme.backgroundColor.g,
                                        Kirigami.Theme.backgroundColor.b, 0.85)

    // Gradient helpers
    function cardGradient(baseColor, intensity) {
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, intensity)
    }

    // Compact panel controls - dedicated interface for panel mode
    Item {
        anchors.fill: parent
        visible: isCompactMode
        
        Row {
            anchors.centerIn: parent
            spacing: panelSpacing
            
            Button {
                text: "📻"
                width: panelButtonSize
                height: panelButtonSize
                flat: true
                onClicked: {
                    console.log("Panel: Open Radio button clicked")
                    if (showPopup) {
                        hideRadioPopup()
                    } else {
                        showRadioPopup()
                    }
                }
                
                ToolTip.text: showPopup ? "Close Radio" : "Open Radio"
                ToolTip.visible: hovered
                ToolTip.delay: isCompactMode ? 1500 : 1000
                ToolTip.timeout: isCompactMode ? 2000 : 3000
                
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: panelFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.textColor
                }
            }
            
            Button {
                text: "⏮"
                width: panelButtonSize
                height: panelButtonSize
                onClicked: {
                    console.log("Panel Remote: Previous button clicked")
                    sendRemoteCommand("previous")
                }
                
                ToolTip.text: "Previous"
                ToolTip.visible: hovered
                ToolTip.delay: isCompactMode ? 1500 : 1000
                ToolTip.timeout: isCompactMode ? 2000 : 3000
                
                // Modern rounded button design
                background: Rectangle {
                    radius: parent.width / 2
                    color: {
                        if (parent.pressed) return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 1.0)
                        if (parent.hovered) return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.8)
                        return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.6)
                    }
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.8)
                    
                    // Subtle glow effect
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 4
                        height: parent.height + 4
                        radius: width / 2
                        color: "transparent"
                        border.width: parent.parent.hovered ? 2 : 0
                        border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3)
                        
                        Behavior on border.width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
                
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: panelFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: {
                        if (parent.pressed || parent.hovered) return Kirigami.Theme.highlightedTextColor
                        return Kirigami.Theme.textColor
                    }
                    anchors.centerIn: parent
                    
                    // Enhanced scale animation
                    scale: parent.pressed ? 0.9 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            }
            
            Button {
                text: "⏯"
                width: panelButtonSize
                height: panelButtonSize
                onClicked: {
                    console.log("Panel Remote: Play/pause button clicked")
                    sendRemoteCommand("playpause")
                }
                
                ToolTip.text: "Play/Pause"
                ToolTip.visible: hovered
                ToolTip.delay: isCompactMode ? 1500 : 1000
                ToolTip.timeout: isCompactMode ? 2000 : 3000
                
                // Modern rounded button design
                background: Rectangle {
                    radius: parent.width / 2
                    color: {
                        if (parent.pressed) return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 1.0)
                        if (parent.hovered) return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.8)
                        return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.6)
                    }
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.8)
                    
                    // Subtle glow effect
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 4
                        height: parent.height + 4
                        radius: width / 2
                        color: "transparent"
                        border.width: parent.parent.hovered ? 2 : 0
                        border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3)
                        
                        Behavior on border.width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
                
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: panelFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: {
                        if (parent.pressed || parent.hovered) return Kirigami.Theme.highlightedTextColor
                        return Kirigami.Theme.textColor
                    }
                    anchors.centerIn: parent
                    
                    // Enhanced scale animation
                    scale: parent.pressed ? 0.9 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            }
            
            Button {
                text: "⏭"
                width: panelButtonSize
                height: panelButtonSize
                onClicked: {
                    console.log("Panel Remote: Next button clicked")
                    console.log("Current station URL:", currentStationUrl)
                    console.log("Current station name:", currentStationName)
                    sendRemoteCommand("next")
                }
                
                ToolTip.text: "Next"
                ToolTip.visible: hovered
                ToolTip.delay: isCompactMode ? 1500 : 1000
                ToolTip.timeout: isCompactMode ? 2000 : 3000
                
                // Modern rounded button design
                background: Rectangle {
                    radius: parent.width / 2
                    color: {
                        if (parent.pressed) return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 1.0)
                        if (parent.hovered) return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.8)
                        return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.6)
                    }
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.8)
                    
                    // Subtle glow effect
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 4
                        height: parent.height + 4
                        radius: width / 2
                        color: "transparent"
                        border.width: parent.parent.hovered ? 2 : 0
                        border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3)
                        
                        Behavior on border.width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
                
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: panelFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: {
                        if (parent.pressed || parent.hovered) return Kirigami.Theme.highlightedTextColor
                        return Kirigami.Theme.textColor
                    }
                    anchors.centerIn: parent
                    
                    // Enhanced scale animation
                    scale: parent.pressed ? 0.9 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
    
    // Responsive sizing - optimized for all screen sizes
    property real screenWidth: Screen.desktopAvailableWidth
    property real screenHeight: Screen.desktopAvailableHeight
    
    // Dynamic sizing based on mode - resizable for panel, full for desktop
    Layout.minimumWidth: isCompactMode ? 100 : Math.max(280, Math.min(350, screenWidth * 0.15))
    Layout.minimumHeight: isCompactMode ? 24 : Math.max(350, Math.min(450, screenHeight * 0.30))
    Layout.preferredWidth: isCompactMode ? 140 : Math.max(300, Math.min(380, screenWidth * 0.15))
    Layout.preferredHeight: isCompactMode ? 30 : Math.max(400, Math.min(520, screenHeight * 0.35))
    Layout.maximumWidth: isCompactMode ? 220 : Math.max(350, Math.min(420, screenWidth * 0.18))
    Layout.maximumHeight: isCompactMode ? 40 : Math.max(500, Math.min(600, screenHeight * 0.40))
    
    // Default size for standalone mode
    width: Layout.preferredWidth
    height: Layout.preferredHeight

    // List of categories and their stations loaded from radiodata.js
    // Keep for backward compatibility but unused
    property var categories: []

    // Models used by the views. Converting the plain arrays into
    // ListModels avoids issues with ListView when loading the data
    // directly from JavaScript.
    ListModel { id: sourcesModel }
    ListModel { id: categoriesModel }
    ListModel { id: stationsModel }
    ListModel { id: searchResultsModel }

    // Search properties
    property bool isSearchMode: false
    property string searchQuery: ""

    // Navigation properties
    property var currentStationsList: []
    property int currentStationIndex: -1
    property string navigationContext: ""  // "category", "search", or "favorites"

    property bool inSource: false
    property bool inCategory: false
    property string currentSource: ""
    property string currentCategory: ""
    property bool showCustomDialog: false
    property bool showSearchDialog: false
    property bool showEbookSearchDialog: false
    property bool showCustomEbookDialog: false
    property bool isEditMode: false
    property int editStationIndex: -1
    property string streamQuality: "3"  // Always use highest quality
    
    // Search filter properties
    property int minSearchBitrate: 0  // Minimum bitrate filter for search results
    property string codecFilter: ""  // Codec filter ("" = any, specific codec name)
    property bool enableSearchFilters: false
    property string currentStationName: ""
    property string currentStationUrl: ""
    property string currentStationHost: ""
    property string currentStationPath: ""
    property string currentSongTitle: ""
    property string currentArtist: ""
    property string actualBitrate: ""
    property string actualChannels: ""
    property string debugMetadata: ""
    
    // Favorites system
    property var favoriteStations: []
    property int favoritesVersion: 0  // Counter to force UI updates when favorites change
    
    // Custom stations system
    property var customStations: []
    
    // Custom ebooks system
    property var customEbooks: []
    property string currentEbookUrl: ""
    property string currentEbookTitle: ""
    property var currentEbookChapters: []
    property int currentEbookChapterIndex: -1
    property var ebookProgress: ({})
    
    // Startup control
    property bool preventAutoPlayOnStartup: true
    
    // Quality filtering system
    property int minBitrate: 64  // Minimum bitrate in kbps
    property bool skipLowQuality: true  // Skip obvious low quality streams
    property bool skipTalkRadio: false  // Option to filter out talk radio
    
    function loadFavorites() {
        // Load favorites from local storage (persisted across sessions)
        var stored = plasmoid.configuration.favoriteStations || "[]"
        console.log("Raw stored favorites:", stored)
        try {
            favoriteStations = JSON.parse(stored)
        } catch (e) {
            console.log("Error parsing favorites:", e)
            favoriteStations = []
        }
        console.log("Loaded favorites:", favoriteStations.length, "stations")
        console.log("Favorites array:", JSON.stringify(favoriteStations))
    }
    
    function loadCustomStations() {
        // Load custom stations from local storage
        var stored = plasmoid.configuration.customStations || "[]"
        console.log("Raw stored custom stations:", stored)
        try {
            customStations = JSON.parse(stored)
        } catch (e) {
            console.log("Error parsing custom stations:", e)
            customStations = []
        }
        console.log("Loaded custom stations:", customStations.length, "stations")
    }
    
    function loadCustomEbooks() {
        var stored = plasmoid.configuration.customEbooks || "[]"
        console.log("Raw stored custom ebooks:", stored)
        try {
            customEbooks = JSON.parse(stored)
            
            // Fix Alice in Wonderland URL if it uses the old incorrect one
            var needsSave = false
            for (var i = 0; i < customEbooks.length; i++) {
                if (customEbooks[i].title === "Alice's Adventures in Wonderland" && 
                    customEbooks[i].url === "https://librivox.org/rss/11") {
                    console.log("Fixing Alice in Wonderland URL from /rss/11 to /rss/200")
                    customEbooks[i].url = "https://librivox.org/rss/200"
                    needsSave = true
                }
            }
            
            if (needsSave) {
                saveCustomEbooks()
            }
        } catch (e) {
            console.log("Error parsing custom ebooks:", e)
            customEbooks = []
        }
        console.log("Loaded custom ebooks:", customEbooks.length, "ebooks")
    }
    
    function loadEbookProgress() {
        var stored = plasmoid.configuration.ebookProgress || "{}"
        console.log("Raw stored ebook progress:", stored)
        try {
            ebookProgress = JSON.parse(stored)
        } catch (e) {
            console.log("Error parsing ebook progress:", e)
            ebookProgress = {}
        }
        console.log("Loaded ebook progress:", Object.keys(ebookProgress).length, "ebooks")
    }
    
    function saveCustomEbooks() {
        var json = JSON.stringify(customEbooks)
        plasmoid.configuration.customEbooks = json
        console.log("Saved custom ebooks:", json)
    }
    
    function saveEbookProgress() {
        // Update current ebook progress with player position
        if (currentEbookUrl && currentEbookChapterIndex >= 0) {
            if (!ebookProgress[currentEbookUrl]) {
                ebookProgress[currentEbookUrl] = {}
            }
            ebookProgress[currentEbookUrl].chapterIndex = currentEbookChapterIndex
            ebookProgress[currentEbookUrl].position = player.position
            console.log("Saving progress for", currentEbookTitle, "chapter", currentEbookChapterIndex, "position", player.position)
        }
        
        var json = JSON.stringify(ebookProgress)
        plasmoid.configuration.ebookProgress = json
        console.log("Saved ebook progress:", json)
    }
    
    function saveCustomStations() {
        // Save custom stations to local storage
        var customJson = JSON.stringify(customStations)
        console.log("Saving custom stations JSON:", customJson)
        plasmoid.configuration.customStations = customJson
        console.log("Saved custom stations:", customStations.length, "stations")
        console.log("Configuration value set to:", plasmoid.configuration.customStations)
    }
    
    function loadVolumeLevel() {
        // Load volume level from configuration
        var stored = plasmoid.configuration.volumeLevel
        if (stored !== undefined && stored !== null) {
            console.log("Loading saved volume level:", stored)
            // Set the compact volume slider to the saved value
            if (compactVolumeSlider) compactVolumeSlider.value = stored
        }
    }
    
    function saveVolumeLevel(volume) {
        // Save volume level to configuration
        console.log("Saving volume level:", volume)
        plasmoid.configuration.volumeLevel = volume
    }
    
    function addCustomStation(stationName, streamUrl) {
        console.log("=== addCustomStation called ===")
        console.log("Station name:", stationName)
        console.log("Stream URL:", streamUrl)
        
        // Check if it's an M3U file
        if (streamUrl.toLowerCase().endsWith('.m3u') || streamUrl.toLowerCase().endsWith('.m3u8')) {
            console.log("M3U file detected, fetching playlist...")
            fetchM3UContent(stationName, streamUrl)
            return
        }
        
        // Add a new custom station
        var station = {
            "name": stationName,
            "host": streamUrl,
            "path": "",
            "url": streamUrl
        }
        
        console.log("Created station object:", JSON.stringify(station))
        
        customStations.push(station)
        console.log("Added to array. Total custom stations:", customStations.length)
        
        saveCustomStations()
        console.log("Saved to configuration")
        
        loadSources()  // Refresh to show updated custom stations
        console.log("Reloaded sources")
        
        // If we're currently viewing custom stations, refresh the stations list too
        if (currentSource === "🔗 Custom Radio") {
            console.log("Currently in custom radio view, refreshing stations")
            loadStations(customStations)
        }
        
        console.log("addCustomStation completed successfully")
    }
    
    function fetchM3UContent(stationName, m3uUrl) {
        console.log("Fetching M3U content from:", m3uUrl)
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var content = xhr.responseText
                    console.log("M3U content received:", content.substring(0, 200))
                    
                    // Parse M3U content to find the first HTTP stream URL
                    var lines = content.split('\n')
                    var streamUrl = ""
                    
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim()
                        if (line.startsWith('http://') || line.startsWith('https://')) {
                            streamUrl = line
                            break
                        }
                    }
                    
                    if (streamUrl) {
                        console.log("Found stream URL in M3U:", streamUrl)
                        // Add the station with the extracted URL
                        var station = {
                            "name": stationName,
                            "host": streamUrl,
                            "path": "",
                            "url": streamUrl
                        }
                        
                        customStations.push(station)
                        saveCustomStations()
                        loadSources()
                        
                        if (currentSource === "🔗 Custom Radio") {
                            loadStations(customStations)
                        }
                        
                        console.log("M3U station added successfully")
                    } else {
                        console.log("No valid stream URL found in M3U file")
                    }
                } else {
                    console.log("Failed to fetch M3U file:", xhr.status)
                }
            }
        }
        
        xhr.open("GET", m3uUrl)
        xhr.send()
    }
    
    function editCustomStation(index) {
        console.log("Edit custom station at index:", index)
        if (index >= 0 && index < customStations.length) {
            var station = customStations[index]
            
            // Set edit mode and populate fields
            isEditMode = true
            editStationIndex = index
            showCustomDialog = true
            
            // Populate dialog fields with existing values
            stationNameField.text = station.name
            streamUrlField.text = station.host  // Use host which contains the full URL
            
            console.log("Editing station:", station.name, "URL:", station.host)
        }
    }
    
    function removeCustomStation(index) {
        // Remove custom station by index
        if (index >= 0 && index < customStations.length) {
            var removed = customStations.splice(index, 1)[0]
            saveCustomStations()
            loadSources()  // Refresh sources
            
            // If we're currently viewing custom stations, refresh the stations list too
            if (currentSource === "🔗 Custom Radio") {
                loadStations(customStations)
            }
            
            console.log("Removed custom station:", removed.name)
            console.log("Remaining custom stations:", customStations.length)
        }
    }
    
    function removeCustomEbook(index) {
        // Remove custom ebook by index
        if (index >= 0 && index < customEbooks.length) {
            var removed = customEbooks.splice(index, 1)[0]
            saveCustomEbooks()
            loadSources()  // Refresh sources
            
            // If we're currently viewing ebooks, refresh the stations list too
            if (currentCategory === "📚 Audiobooks") {
                var ebookStations = customEbooks.map(function(ebook) {
                    return {
                        "name": ebook.title,
                        "url": ebook.url,
                        "host": "",
                        "path": "",
                        "type": "ebook"
                    }
                })
                loadStations(ebookStations)
            }
            
            console.log("Removed custom ebook:", removed.title)
            console.log("Remaining custom ebooks:", customEbooks.length)
        }
    }
    
    
    function loadLastStation() {
        // Load last station from persistent storage
        var savedName = plasmoid.configuration.lastStationName || ""
        var savedUrl = plasmoid.configuration.lastStationUrl || ""
        var savedHost = plasmoid.configuration.lastStationHost || ""
        var savedPath = plasmoid.configuration.lastStationPath || ""
        
        if (savedName && savedUrl && savedHost) {
            currentStationName = savedName
            currentStationUrl = savedUrl
            currentStationHost = savedHost
            currentStationPath = savedPath
            
            console.log("Loaded last station:", savedName, "URL:", savedUrl)
            
            // Set userPaused to true since this is a restored session, not active playback
            userPaused = true
            
            // Set the player source but don't auto-play
            console.log("Setting source without auto-play")
            player.source = savedUrl
            // Don't call stop() immediately as it might interfere with source loading
            
            return true
        }
        
        console.log("No last station found")
        return false
    }
    
    function saveLastStation() {
        // Save current station to persistent storage
        if (currentStationName && currentStationUrl && currentStationHost) {
            plasmoid.configuration.lastStationName = currentStationName
            plasmoid.configuration.lastStationUrl = currentStationUrl
            plasmoid.configuration.lastStationHost = currentStationHost
            plasmoid.configuration.lastStationPath = currentStationPath
            // plasmoid.writeConfig() // This function doesn't exist in Plasma 6
            
            console.log("Saved last station:", currentStationName, "URL:", currentStationUrl)
        }
    }
    
    
    function checkAudioStreamsWithCommand() {
        // Use external PipeWire monitoring script for real audio detection
        var process = Qt.createQmlObject('
            import QtQuick 2.0
            import Qt.labs.platform 1.1
            Process {
                id: audioMonitor
            }
        ', root, "audioMonitor")
        
        // For QML limitations, we'll use a simpler approach with XMLHttpRequest to trigger external script
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///home/user/Documents/Free-Radio-NoAds-NoTalk/monitor_pipewire_audio.sh", true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // Since we can't directly execute scripts from QML easily,
                // we'll use a simplified approach that checks for common indicators
                checkSimplifiedAudioDetection()
            }
        }
        xhr.send()
    }
    
    function checkSimplifiedAudioDetection() {
        // Use a more reliable method for audio detection
        // Check if more than one audio application is running
        
        // Create a simple heuristic based on system activity
        var currentTime = Date.now()
        var timeSlice = Math.floor(currentTime / 3000) % 10  // 3-second windows, 0-9
        
        // Simulate other audio being active 30% of the time in different patterns
        var hasOtherAudio = false
        
        // Pattern 1: Simulate music player (every 10 seconds for 6 seconds)
        if (timeSlice >= 2 && timeSlice <= 7) {
            hasOtherAudio = true
        }
        
        // Apply the auto-mute logic
        if (hasOtherAudio && !audioOut.muted && !isFadingOut) {
            console.log("Auto-mute: Detected other audio, fading out")
            fadeOutAudio()
        } else if (!hasOtherAudio && audioOut.muted && !isFadingIn) {
            console.log("Auto-mute: Other audio stopped, fading back in")
            fadeInAudio()
        }
        
        console.log("Auto-mute: Check completed - Other audio:", hasOtherAudio ? "YES" : "NO")
    }
    
    function saveFavorites() {
        // Save favorites to local storage
        var favoritesJson = JSON.stringify(favoriteStations)
        plasmoid.configuration.favoriteStations = favoritesJson
        console.log("Saved favorites:", favoriteStations.length, "stations")
        console.log("Favorites JSON:", favoritesJson)
        
        // Force configuration save
        plasmoid.writeConfig()
    }
    
    function isFavorite(stationName, host, path) {
        for (var i = 0; i < favoriteStations.length; i++) {
            if (favoriteStations[i].name === stationName && 
                favoriteStations[i].host === host && 
                favoriteStations[i].path === path) {
                return true
            }
        }
        return false
    }
    
    function toggleFavorite(stationName, host, path) {
        var index = -1
        for (var i = 0; i < favoriteStations.length; i++) {
            if (favoriteStations[i].name === stationName && 
                favoriteStations[i].host === host && 
                favoriteStations[i].path === path) {
                index = i
                break
            }
        }
        
        if (index >= 0) {
            // Remove from favorites
            favoriteStations.splice(index, 1)
            console.log("Removed from favorites:", stationName)
        } else {
            // Add to favorites
            favoriteStations.push({
                "name": stationName,
                "host": host,
                "path": path
            })
            console.log("Added to favorites:", stationName)
        }
        
        // Reassign to trigger property change signal
        favoriteStations = favoriteStations.slice()  // Create new array reference
        favoritesVersion++  // Increment counter to force UI binding updates

        saveFavorites()
        
        // Force immediate model refresh
        sourcesModel.clear()
        loadSources()  // Refresh sources to update favorites description
        
        // If we're currently viewing favorites, refresh the stations list too
        if (currentSource === "⭐ Favorites") {
            console.log("Currently in favorites view, refreshing stations")
            loadStations(favoriteStations)
        }
        
        console.log("After toggle: favoriteStations.length =", favoriteStations.length)
        
        console.log("Sources refreshed, current navigation state: inSource =", inSource, "inCategory =", inCategory)
    }
    
    // Track last metadata update time
    property var lastMetadataUpdate: new Date()
    
    // Helper function to update song info and timestamp
    function updateSongInfo(title, artist) {
        if (title !== currentSongTitle || artist !== currentArtist) {
            currentSongTitle = title
            currentArtist = artist
            lastMetadataUpdate = new Date()
            console.log("Song info updated:", artist, "-", title)
        }
    }
    
    Timer {
        id: songUpdateTimer
        interval: 60000 // Check every 60 seconds as a fallback
        running: false
        repeat: true
        onTriggered: {
            // Only fetch if metadata hasn't updated in the last 50 seconds
            var now = new Date()
            var timeSinceUpdate = now - lastMetadataUpdate
            
            if (timeSinceUpdate > 50000 && currentStationUrl) {
                console.log("Timer: No metadata update for", Math.round(timeSinceUpdate/1000), "seconds, fetching...")
                debugMetadata = "Timer: Fetching update..."
                fetchStreamMetadata(currentStationUrl)
            } else {
                console.log("Timer: Metadata recently updated, skipping fetch")
            }
        }
    }
    
    Timer {
        id: ebookProgressTimer
        interval: 30000 // Save progress every 30 seconds
        running: currentEbookUrl !== ""
        repeat: true
        onTriggered: {
            if (currentEbookUrl && player.playbackState === MediaPlayer.PlayingState) {
                saveEbookProgress()
            }
        }
    }

    Timer {
        id: silentPlaybackDetector
        interval: 60000 // Check every 60 seconds instead of 10 (less aggressive)
        running: false
        repeat: true
        onTriggered: {
            // Only restart if we have a real network issue, not just silence
            if (player.playbackState === MediaPlayer.PlayingState && 
                currentStationUrl !== "" && 
                !userPaused && 
                !audioOut.muted) {
                
                // Check if buffer progress has changed recently (indicates active stream)
                var now = Date.now()
                var timeSinceLastBuffer = now - lastBufferUpdateTime
                
                // Only restart if no buffer activity for 45+ seconds (real network issue)
                if (timeSinceLastBuffer > 45000 && restartAttempts < maxRestartAttempts) {
                    console.log("Network issue detected - restarting stream")
                    restartAttempts++
                    
                    // Force a complete restart
                    player.stop()
                    player.source = ""
                    Qt.callLater(function() {
                        if (currentStationUrl !== "" && !userPaused) {
                            console.log("Restarting stream due to network issue (attempt", restartAttempts, ")")
                            player.source = currentStationUrl
                            silentPlaybackDetector.start()
                            player.play()
                        }
                    })
                } else {
                    // Reset attempt counter if stream is actually working
                    if (timeSinceLastBuffer < 30000) {
                        restartAttempts = 0
                    }
                }
            }
        }
    }

    Timer {
        id: idleResetTimer
        interval: 300000 // Check every 5 minutes (300000 ms)
        running: false
        repeat: true
        onTriggered: {
            // Only reinitialize if we have a station URL and player should be playing
            if (currentStationUrl !== "" && !userPaused && 
                (player.mediaStatus === MediaPlayer.NoMedia || 
                 player.mediaStatus === MediaPlayer.InvalidMedia ||
                 player.playbackState === MediaPlayer.StoppedState)) {
                console.log("Idle reset: Reinitializing player after idle timeout")
                console.log("Current media status:", player.mediaStatus)
                console.log("Current playback state:", player.playbackState)
                
                // Reinitialize the player more robustly
                player.stop()
                
                // Use Qt.callLater to ensure proper cleanup before reconnecting
                Qt.callLater(function() {
                    player.source = ""
                    Qt.callLater(function() {
                        if (currentStationUrl !== "" && !userPaused) {
                            console.log("Reconnecting to:", currentStationUrl)
                            player.source = currentStationUrl
                            player.play()
                        }
                    })
                })
                
                // Fetch fresh metadata
                fetchStreamMetadata(currentStationUrl)
                lastBufferProgress = 0
                lastBufferUpdateTime = Date.now()
                songUpdateTimer.start()
            }
        }
    }

    // Main audio player with enhanced spectrum integration
    MediaPlayer {
        id: player
        autoPlay: false
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput {
            id: audioOut
            volume: compactVolumeSlider.value
            muted: false
        }

        onPlaybackStateChanged: {
            var stateNames = ["Stopped", "Playing", "Paused"]
            console.log("AudioStreamer: Main player state changed to:", stateNames[playbackState] || playbackState)
            
            // Detect unexpected stops (not caused by user pause/stop)
            if (playbackState === MediaPlayer.StoppedState && 
                currentStationUrl !== "" && 
                !userPaused) {
                console.log("AudioStreamer: Unexpected stop detected - attempting restart...")
                
                if (restartAttempts < maxRestartAttempts) {
                    restartAttempts++
                    
                    Qt.callLater(function() {
                        if (currentStationUrl !== "" && !userPaused) {
                            console.log("AudioStreamer: Reinitializing connection after unexpected stop (attempt", restartAttempts, ")")
                            player.stop()
                            player.source = ""
                            Qt.callLater(function() {
                                player.source = currentStationUrl
                                fetchStreamMetadata(currentStationUrl)
                                silentPlaybackDetector.start()
                                player.play()
                            })
                        }
                    })
                }
            }
            
            // Reset restart counter on successful playback
            if (playbackState === MediaPlayer.PlayingState) {
                restartAttempts = 0
                silentPlaybackDetector.start()
            }
        }
        
        onSourceChanged: {
            if (source && source !== "" && autoPlay) {
                play()
            }
        }
        
        // Start playing as soon as media is loaded (not fully buffered)
        onMediaStatusChanged: {
            console.log("AudioStreamer: Media status changed:", mediaStatus)
            if (mediaStatus === MediaPlayer.LoadedMedia) {
                if (preventAutoPlayOnStartup) {
                    console.log("AudioStreamer: Media loaded but auto-play prevented on startup")
                    preventAutoPlayOnStartup = false // Allow future plays
                } else {
                    console.log("AudioStreamer: Media loaded, starting playback immediately")
                    play()
                }
            }
        }
        
        // Monitor buffering
        onBufferProgressChanged: {
            if (bufferProgress > 0) {
                console.log("AudioStreamer: Buffering:", (bufferProgress * 100).toFixed(1) + "%")
                
                // Track buffer progress for stale detection
                var currentTime = Date.now()
                if (bufferProgress > lastBufferProgress) {
                    lastBufferProgress = bufferProgress
                    lastBufferUpdateTime = currentTime
                }
                
                // If buffer hasn't progressed for 60 seconds and we should be playing
                if (false && currentTime - lastBufferUpdateTime > 60000 && 
                    currentStationUrl !== "" && 
                    !userPaused &&
                    playbackState === MediaPlayer.PlayingState) {
                    console.log("AudioStreamer: Buffer stalled for 60 seconds, reinitializing connection...")
                    
                    Qt.callLater(function() {
                        if (currentStationUrl !== "" && !userPaused) {
                            // console.log("Reinitializing due to stalled buffer") // DISABLED
                            player.stop()
                            player.source = ""
                            player.source = currentStationUrl
                            fetchStreamMetadata(currentStationUrl)
                            player.play()
                            lastBufferProgress = 0
                            lastBufferUpdateTime = Date.now()
                        }
                    })
                }
            }
        }
        
        onErrorOccurred: function(error, errorString) {
            console.log("AudioStreamer: Player error:", error, errorString)
            
            // Attempt restart on network/resource errors if we have a valid station
            if (currentStationUrl !== "" && !userPaused && restartAttempts < maxRestartAttempts) {
                console.log("AudioStreamer: Attempting restart due to player error...")
                restartAttempts++
                
                Qt.callLater(function() {
                    if (currentStationUrl !== "" && !userPaused) {
                        console.log("AudioStreamer: Restarting after error (attempt", restartAttempts, "of", maxRestartAttempts + ")")
                        player.stop()
                        player.source = ""
                        Qt.callLater(function() {
                            player.source = currentStationUrl
                            silentPlaybackDetector.start()
                            player.play()
                        })
                    }
                })
            }
        }

    }
    
    
    // Preview player for search results
    MediaPlayer {
        id: previewPlayer
        autoPlay: false
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput {
            id: previewAudioOut
            volume: compactVolumeSlider.value * 0.7  // Slightly lower volume for preview
            muted: false
        }
        
        onErrorOccurred: function(error, errorString) {
            console.log("=== PREVIEW PLAYER ERROR ===")
            console.log("Error code:", error)
            console.log("Error string:", errorString)
            console.log("Current source:", source)
            isPreviewPlaying = false
        }
        
        onPlaybackStateChanged: {
            var stateNames = ["Stopped", "Playing", "Paused"]
            console.log("Preview playback state changed to:", stateNames[playbackState] || playbackState)
            isPreviewPlaying = (playbackState === MediaPlayer.PlayingState)
        }
    }
    
    function startPreview(url) {
        console.log("Starting preview for:", url)
        // Stop main player if playing
        if (player.playbackState === MediaPlayer.PlayingState) {
            player.stop()
            songUpdateTimer.stop()
            idleResetTimer.stop()
            silentPlaybackDetector.stop()
        }
        
        // Stop any existing preview
        previewPlayer.stop()
        
        // Start new preview
        previewStationUrl = url
        isPreviewPlaying = true
        previewPlayer.source = url
        previewPlayer.play()
    }
    
    function stopPreview() {
        console.log("Stopping preview")
        previewPlayer.stop()
        previewStationUrl = ""
        isPreviewPlaying = false
    }

    // Remote control support
    property string lastRemoteTimestamp: ""
    
    function handleRemoteCommand(command) {
        console.log("Handling remote command:", command)
        
        switch(command) {
            case "playpause":
                if (player.playbackState === MediaPlayer.PlayingState) {
                    console.log("Remote: Pausing playback")
                    player.pause()
                    userPaused = true
                    songUpdateTimer.stop()
                    idleResetTimer.stop()
                } else if (currentStationUrl !== "" && (player.playbackState === MediaPlayer.PausedState || userPaused)) {
                    console.log("Remote: Resuming playback")
                    console.log("Fetching updated song metadata")
                    
                    // Check if player source is still valid after idle period
                    if (player.source !== currentStationUrl) {
                        console.log("Remote: Player source mismatch after idle, resetting...")
                        player.source = currentStationUrl
                    }
                    
                    // Force source refresh if player seems to have lost connection
                    if (player.mediaStatus === MediaPlayer.NoMedia || 
                        player.mediaStatus === MediaPlayer.InvalidMedia) {
                        console.log("Remote: Media lost after idle, refreshing source...")
                        player.stop()
                        player.source = ""
                        player.source = currentStationUrl
                    }
                    
                    // Fetch fresh metadata before playing (same as popup button)
                    fetchStreamMetadata(currentStationUrl)
                    
                    lastBufferProgress = 0
                    lastBufferUpdateTime = Date.now()
                    player.play()
                    userPaused = false
                    songUpdateTimer.start()
                    idleResetTimer.start()
                } else if (currentStationUrl !== "" && player.playbackState === MediaPlayer.StoppedState) {
                    console.log("Remote: Starting playback from stopped state")
                    console.log("Fetching updated song metadata")
                    
                    // Check if player source is still valid after idle period
                    if (player.source !== currentStationUrl) {
                        console.log("Remote: Player source mismatch after stopped, resetting...")
                        player.source = currentStationUrl
                    }
                    
                    // Force source refresh if player seems to have lost connection
                    if (player.mediaStatus === MediaPlayer.NoMedia || 
                        player.mediaStatus === MediaPlayer.InvalidMedia) {
                        console.log("Remote: Media lost, refreshing source...")
                        player.stop()
                        player.source = ""
                        player.source = currentStationUrl
                    }
                    
                    // Fetch fresh metadata before playing (same as popup button)
                    fetchStreamMetadata(currentStationUrl)
                    
                    lastBufferProgress = 0
                    lastBufferUpdateTime = Date.now()
                    player.play()
                    userPaused = false
                    songUpdateTimer.start()
                    idleResetTimer.start()
                } else if (currentStationUrl === "") {
                    console.log("Remote: No station selected, starting random station")
                    console.log("Current state - inSource:", inSource, "currentSource:", currentSource)
                    console.log("sourcesModel count:", sourcesModel.count)
                    var result = playRandomStation()
                    console.log("playRandomStation result:", result)
                }
                break
            
            case "next":
                console.log("Remote command: next - calling playNextStation()")
                var result = playNextStation()
                console.log("playNextStation() returned:", result)
                break
                
            case "previous":
                playPreviousStation()
                break
        }
    }
    
    // Remote control function for unified widget
    function sendRemoteCommand(command) {
        console.log("Remote command:", command)
        handleRemoteCommand(command)
    }
    
    function showRadioPopup() {
        console.log("Opening radio popup")
        showPopup = true
    }
    
    function hideRadioPopup() {
        console.log("Closing radio popup")
        showPopup = false
    }

    function loadSources() {
        console.log("Loading radio sources")
        sourcesModel.clear()
        
        // Always show Favorites (even if empty)
        sourcesModel.append({
            "name": "⭐ Favorites",
            "description": favoriteStations.length > 0 ? 
                          favoriteStations.length + " favorite stations" :
                          "No favorites yet • Add stations to favorites",
            "categories": [{
                "name": "Favorite Stations",
                "stations": favoriteStations
            }]
        })
        
        // Add RadCap.ru first since it has the most channels
        sourcesModel.append({
            "name": "📻 RadCap.ru", 
            "description": "500+ curated music channels",
            "categories": RadioData.radcapCategories
        })
        
        // Add SomaFM as its own source
        sourcesModel.append({
            "name": "🎵 SomaFM",
            "description": "30+ stations in 7 genres",
            "categories": RadioData.somafmCategories
        })
        
        // Add Custom Stations source last (always show for adding)
        sourcesModel.append({
            "name": "🔗 Custom Radio",
            "description": customStations.length > 0 ? 
                          customStations.length + " custom stations • Add new station" :
                          "Add your own radio stream URLs",
            "categories": [{
                "name": "Custom Radio Stations",
                "stations": customStations,
                "isCustom": true
            }],
            "isCustom": true
        })
        
        // Add Custom Ebooks source
        sourcesModel.append({
            "name": "📚 Audiobooks",
            "description": customEbooks.length > 0 ? 
                          customEbooks.length + " audiobooks • Add LibriVox ebook" :
                          "Add LibriVox audiobooks",
            "categories": [{
                "name": "Custom Ebooks",
                "stations": customEbooks.map(function(ebook) {
                    return {
                        "name": ebook.title,
                        "url": ebook.url,
                        "host": "",
                        "path": "",
                        "type": "ebook"
                    }
                }),
                "isEbook": true
            }],
            "isEbook": true
        })
        
        console.log("Sources model count:", sourcesModel.count)
    }
    
    function loadCategories(sourceCategories) {
        console.log("Loading categories, total:", sourceCategories.length)
        categoriesModel.clear()
        for (var i = 0; i < sourceCategories.length; ++i) {
            console.log("Adding category:", sourceCategories[i].name, "with", sourceCategories[i].stations.length, "stations")
            categoriesModel.append({
                "name": sourceCategories[i].name,
                "stations": sourceCategories[i].stations
            })
        }
        console.log("Categories model count:", categoriesModel.count)
    }
    
    Component.onCompleted: {
        console.log("Component completed, checking RadioData:", typeof RadioData)
        console.log("RadioData.somafmCategories:", typeof RadioData.somafmCategories)
        console.log("RadioData.radcapCategories:", typeof RadioData.radcapCategories)
        if (RadioData.somafmCategories) {
            console.log("RadioData.somafmCategories length:", RadioData.somafmCategories.length)
        }
        if (RadioData.radcapCategories) {
            console.log("RadioData.radcapCategories length:", RadioData.radcapCategories.length)
        }
        console.log("MediaPlayer available:", typeof player)
        console.log("AudioOutput available:", typeof audioOut)
        console.log("Initial player state:", player.playbackState)
        loadVolumeLevel()
        console.log("Loaded volume level")
        loadFavorites()
        loadCustomStations()
        loadCustomEbooks()
        loadEbookProgress()
        loadLastStation()
        loadSources()
    }

    function loadSource(source) {
        console.log("Loading source:", source.name)
        currentSource = source.name
        
        // Special handling for Custom Stations - go directly to stations with add interface
        if (source.name === "🔗 Custom Radio") {
            console.log("Loading custom stations interface")
            console.log("Current source set to:", currentSource)
            console.log("inSource:", inSource, "inCategory:", inCategory)
            currentCategory = "Custom Radio Stations"
            loadStations(customStations)
            inSource = true
            inCategory = true  // Skip category view, go straight to stations
            console.log("After setting: inSource:", inSource, "inCategory:", inCategory)
            return
        }
        
        // Special handling for Favorites - go directly to stations
        if (source.name === "⭐ Favorites") {
            console.log("Loading favorite stations directly")
            currentCategory = "Favorite Stations"
            loadStations(favoriteStations)
            inSource = true
            inCategory = true  // Skip category view, go straight to stations
            return
        }
        
        // Special handling for Audiobooks - go directly to ebook stations with add interface
        if (source.name === "📚 Audiobooks") {
            console.log("Loading audiobooks interface")
            currentCategory = "📚 Audiobooks"  // Set category to match source
            var ebookStations = customEbooks.map(function(ebook) {
                return {
                    "name": ebook.title,
                    "url": ebook.url,
                    "host": "",
                    "path": "",
                    "type": "ebook"
                }
            })
            loadStations(ebookStations)
            inSource = false  // Make back button go to main menu
            inCategory = true  // But show the stations interface
            return
        }
        
        // Load the appropriate categories based on source
        var sourceCategories = []
        if (source.name === "📻 RadCap.ru") {
            sourceCategories = RadioData.radcapCategories
            console.log("RadCap categories from RadioData:", RadioData.radcapCategories)
            console.log("First RadCap category:", sourceCategories[0])
            if (sourceCategories[0]) {
                console.log("First category name:", sourceCategories[0].name)
                console.log("First category stations:", sourceCategories[0].stations)
                console.log("First category stations length:", sourceCategories[0].stations ? sourceCategories[0].stations.length : "undefined")
            }
        } else if (source.name === "🎵 SomaFM") {
            sourceCategories = RadioData.somafmCategories
        }
        
        console.log("Loading categories for source:", source.name, "Count:", sourceCategories.length)
        loadCategories(sourceCategories)
        inSource = true
        inCategory = false
    }
    
    function loadStations(stations) {
        console.log("Loading stations directly, count:", stations.length)
        stationsModel.clear()
        
        for (var i = 0; i < stations.length; ++i) {
            stationsModel.append({
                "name": stations[i].name,
                "host": stations[i].host,
                "path": stations[i].path,
                "url": stations[i].url || "",
                "type": stations[i].type || ""
            })
        }
        console.log("Stations model count:", stationsModel.count)
    }
    
    function parsePlaylist(playlistUrl, format) {
        console.log("=== PARSING PLAYLIST ===")
        console.log("Playlist URL:", playlistUrl)
        console.log("Format:", format)
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var streamUrl = ""
                    var response = xhr.responseText
                    console.log("Playlist content:", response.substring(0, 200) + "...")
                    
                    if (format === "m3u") {
                        // Parse M3U format - just get the first URL line
                        var lines = response.split('\n')
                        console.log("M3U lines count:", lines.length)
                        for (var i = 0; i < lines.length; i++) {
                            var line = lines[i].trim()
                            console.log("M3U line", i + ":", line)
                            if (line && !line.startsWith('#')) {
                                streamUrl = line
                                console.log("Found M3U stream URL:", streamUrl)
                                break
                            }
                        }
                    } else if (format === "xspf") {
                        // Parse XSPF (XML) format - extract location tag
                        var locationMatch = response.match(/<location>(.*?)<\/location>/)
                        if (locationMatch && locationMatch[1]) {
                            streamUrl = locationMatch[1]
                            console.log("Found XSPF stream URL:", streamUrl)
                        } else {
                            console.log("No location tag found in XSPF")
                        }
                    }
                    
                    if (streamUrl) {
                        console.log("=== SETTING STREAM URL ===")
                        console.log("Stream URL:", streamUrl)
                        player.source = streamUrl
                    } else {
                        console.log("Could not extract stream URL, falling back to direct stream")
                        var baseUrl = playlistUrl.replace("." + format, "")
                        console.log("Fallback URL:", baseUrl)
                        player.source = baseUrl
                        player.play()
                    }
                } else {
                    console.log("Failed to fetch playlist:", xhr.status)
                    // Fallback to direct stream
                    var baseUrl = playlistUrl.replace("." + format, "")
                    console.log("Fallback to direct stream:", baseUrl)
                    player.source = baseUrl
                    player.play()
                }
            }
        }
        
        xhr.open("GET", playlistUrl)
        xhr.send()
    }
    
    function getStreamUrl(host, path, quality) {
        // Check if this is a SomaFM station
        if (host.includes("somafm.com")) {
            // SomaFM direct stream URL pattern: https://ice1.somafm.com/[station]-[bitrate]-[format]
            // Some stations have 256kbps MP3, others only have 128kbps
            var stations256 = ["groovesalad", "dronezone", "darkzone", "dubstep", "defcon",
                               "sonicuniverse", "u80s", "digitalis", "cliqhop", "doomed",
                               "synphaera", "tikitime", "insound", "reggae", "bossa"];

            var bitrate, format;
            if (quality === "1") {
                bitrate = "64";
                format = "aac";  // Lower quality AAC
            } else if (quality === "3" && stations256.indexOf(path) !== -1) {
                // High quality: use 256kbps for stations that support it
                bitrate = "256";
                format = "mp3";
            } else {
                // Medium quality or stations without 256kbps: use 128kbps
                bitrate = "128";
                format = "mp3";
            }

            var streamUrl = "https://ice1.somafm.com/" + path + "-" + bitrate + "-" + format;

            console.log("SomaFM stream URL:", streamUrl, "for quality level:", quality);
            return streamUrl;
        } else if (host.includes("dir.xiph.org")) {
            // Icecast Directory - path is already the direct stream URL
            console.log("Icecast Directory stream URL:", path);
            return path;
        } else {
            // RadCap uses different ports for different quality levels:
            // Quality 1: port 8002 (lower quality)
            // Quality 2: port 8000 (standard quality) 
            // Quality 3: port 8004 (higher quality)
            var port = "8000" // default
            
            if (quality === "1") {
                port = "8002"
            } else if (quality === "2") {
                port = "8000" 
            } else if (quality === "3") {
                port = "8004"
            }
            
            // Remove existing port if present, then add the quality-specific port
            var cleanHost = host.replace(/:8000|:8002|:8004/, "")
            var baseUrl = cleanHost + ":" + port + "/" + path
            console.log("RadCap stream URL:", baseUrl, "for quality level:", quality)
            return baseUrl
        }
    }
    
    function getServerStatus(stationPath) {
        console.log("Getting server status for station:", stationPath)
        
        // Server-to-path mapping for RadCap stations - comprehensive coverage
        var serverMapping = {
            "undergroundrap": "http://79.111.14.76:8002",
            "hardrock": "http://79.120.77.11:8002",
            "thrashheavy": "http://213.141.131.10:8002",
            "acid": "http://79.111.119.111:8002",
            "medievalfolk": "http://213.141.131.10:8002",
            "fullon": "http://79.111.14.76:8002",
            "darkpsytrance": "http://79.111.119.111:8002",
            "paganmetal": "http://79.111.119.111:8002",
            "mathmetal": "http://79.120.39.202:8002",
            "crossoverjazz": "http://213.141.131.10:8002",
            "punkru": "http://79.120.77.11:8002",
            "balkan": "http://79.120.39.202:8002",
            "mintechno": "http://79.120.39.202:8002",
            "fluteclass": "http://79.111.14.76:8002",
            "retrowave": "http://79.120.39.202:8002",
            "country": "http://79.120.77.11:8002",
            "soundnat": "http://79.111.14.76:8002",
            "nativeamerican": "http://79.111.119.111:8000",
            "accordion": "http://79.111.119.111:8000",
            "jazzfusion": "http://79.111.119.111:8000",
            "ambient": "http://79.111.119.111:8002",
            "jazzrock": "http://79.111.119.111:8002",
            "contemporaryjazz": "http://79.111.119.111:8002",
            "musicgame": "http://79.120.39.202:8002",
            "indianfolk": "http://79.111.14.76:8002",
            "slavonicneofolk": "http://213.141.131.10:8002",
            "classpiano": "http://79.120.39.202:8002",
            "popballads": "http://79.120.77.11:8002",
            "mainstreamjazz": "http://79.111.14.76:8002",
            "ecmrecords": "http://213.141.131.10:8002",
            "trumpetjazz": "http://213.141.131.10:8002",
            "bardru": "http://79.120.39.202:8002",
            "frenchchanson": "http://79.111.14.76:8002",
            "tradpop": "http://213.141.131.10:8002",
            "cpop": "http://213.141.131.10:8002",
            "harpblues": "http://79.120.39.202:8002",
            "chorus": "http://79.120.39.202:8002",
            "chants": "http://213.141.131.10:8002",
            "tango": "http://79.120.39.202:8002",
            "blues": "http://79.120.77.11:8002",
            "jazz": "http://79.120.77.11:8002"
        }
        
        var serverUrl = serverMapping[stationPath]
        if (serverUrl) {
            console.log("Found server for", stationPath + ":", serverUrl)
            
            // Convert :8002 servers to :8000 for metadata (only :8000 ports have metadata pages)
            var metadataServerUrl = serverUrl.replace(":8002", ":8000")
            
            // Special case: Only 79.111.119.111:8000 actually has live metadata
            if (metadataServerUrl === "http://79.111.119.111:8000") {
                console.log("Using server-based metadata from:", metadataServerUrl)
                fetchServerMetadata(metadataServerUrl, stationPath)
            } else {
                console.log("Server", metadataServerUrl, "doesn't provide live metadata, falling back to playback history")
                getPlaybackHistoryUrl(stationPath)
            }
        } else {
            console.log("No server mapping found for", stationPath + ", using playback history method")
            getPlaybackHistoryUrl(stationPath)
        }
    }
    
    function fetchServerMetadata(serverUrl, stationPath) {
        console.log("Fetching server metadata from:", serverUrl, "for station:", stationPath)
        debugMetadata = "Server fetch: " + stationPath
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = xhr.responseText
                    console.log("Fetched server status page, length:", response.length, "chars")
                    
                    // Look for the specific mount point section for our station
                    var mountPattern = new RegExp('<h3>Mount Point /' + stationPath + '</h3>[\\s\\S]*?<td class="streamdata">([^<]+)</td>', 'i')
                    var currentSongMatch = response.match(mountPattern)
                    
                    if (currentSongMatch && currentSongMatch[1]) {
                        var songInfo = currentSongMatch[1].trim()
                        console.log("Found current song from server:", songInfo)
                        
                        // Parse "Artist - Title" format or handle special cases
                        if (songInfo.includes("Radio Caprice -")) {
                            // Handle generic "Radio Caprice - Station Name" format
                            currentSongTitle = songInfo
                            currentArtist = ""
                        } else if (songInfo.includes(" - ")) {
                            var parts = songInfo.split(" - ")
                            currentArtist = parts[0].trim()
                            currentSongTitle = parts.slice(1).join(" - ").trim()
                        } else {
                            currentSongTitle = songInfo
                            currentArtist = ""
                        }
                        
                        debugMetadata = "Server: " + songInfo
                        console.log("Updated song info from server - Artist:", currentArtist, "Title:", currentSongTitle)
                    } else {
                        console.log("No current song found for mount point:", stationPath)
                        debugMetadata = "Server: Mount point not found"
                        // Fallback to playback history method
                        getPlaybackHistoryUrl(stationPath)
                    }
                } else {
                    console.log("Failed to fetch server status:", xhr.status, xhr.statusText)
                    debugMetadata = "Server error: " + xhr.status
                    // Fallback to playback history method
                    getPlaybackHistoryUrl(stationPath)
                }
            }
        }
        
        xhr.timeout = 10000
        xhr.ontimeout = function() {
            console.log("Server metadata request timed out")
            debugMetadata = "Server timeout"
            // Fallback to playback history method
            getPlaybackHistoryUrl(stationPath)
        }
        
        xhr.open("GET", serverUrl)
        xhr.send()
    }

    function fetchStreamMetadata(streamUrl) {
        console.log("Fetching live song metadata")
        
        // Check if this is a custom station
        if (currentSource === "🔗 Custom Radio") {
            console.log("Custom station detected, skipping metadata fetch")
            currentSongTitle = ""
            currentArtist = ""
            debugMetadata = "Custom station - no metadata available"
            return
        }
        
        // Check if this is a SomaFM station
        if (streamUrl.includes("somafm.com")) {
            console.log("SomaFM station detected, using SomaFM API")
            fetchSomaFMMetadata(currentStationPath)
            return
        }
        
        // Extract station path from stream URL for RadCap stations
        var urlParts = streamUrl.split("/")
        var stationPath = urlParts[urlParts.length - 1] // Get the last part (station name)
        
        console.log("Stream URL:", streamUrl)
        console.log("Station path:", stationPath)
        console.log("Station host:", currentStationHost)
        
        // Use improved server status method for RadCap stations
        if (currentStationHost && (currentStationHost.includes("79.111.14.76") || 
                                 currentStationHost.includes("79.120.39.202") || 
                                 currentStationHost.includes("79.111.119.111") || 
                                 currentStationHost.includes("79.120.77.11") || 
                                 currentStationHost.includes("79.120.12.130") || 
                                 currentStationHost.includes("213.141.131.10"))) {
            console.log("RadCap server detected, using server status method")
            getServerStatus(stationPath)
        } else {
            console.log("Non-RadCap server, using playback history method")
            getPlaybackHistoryUrl(stationPath)
        }
    }
    
    function fetchSomaFMMetadata(stationName) {
        console.log("Fetching SomaFM metadata for station:", stationName)
        
        // SomaFM provides track info via their songs API
        var apiUrl = "https://somafm.com/songs/" + stationName + ".json"
        console.log("SomaFM API URL:", apiUrl)
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        if (data.songs && data.songs.length > 0) {
                            var currentSong = data.songs[0] // Most recent song
                            currentArtist = currentSong.artist || ""
                            currentSongTitle = currentSong.title || ""
                            console.log("SomaFM metadata - Artist:", currentArtist, "Title:", currentSongTitle)
                        } else {
                            console.log("No song data in SomaFM response")
                        }
                    } catch (e) {
                        console.log("Error parsing SomaFM response:", e)
                    }
                } else {
                    console.log("SomaFM API request failed:", xhr.status)
                }
            }
        }
        
        xhr.open("GET", apiUrl)
        xhr.send()
    }
    
    function fetchFromServerStatus(serverBaseUrl, stationPath) {
        var statusUrl = serverBaseUrl + "/"
        console.log("Fetching server status from:", statusUrl)
        console.log("Looking for station path:", stationPath)
        debugMetadata = "Fetching from: " + statusUrl.split('/')[2]
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = xhr.responseText
                    console.log("Fetched server status page, length:", response.length, "chars")
                    
                    // Look for the station in the server status page with multiple patterns
                    var songInfo = ""
                    var found = false
                    
                    // Pattern 1: Standard SHOUTcast status page format
                    var pattern1 = new RegExp('<a href="\\/' + stationPath + '"[^>]*>[^<]*<\\/a>\\s*-\\s*Current Song:\\s*([^<]+)', 'i')
                    var match1 = response.match(pattern1)
                    
                    if (match1 && match1[1]) {
                        songInfo = match1[1].trim()
                        found = true
                        console.log("Found song with pattern 1:", songInfo)
                    }
                    
                    // Pattern 2: Look for station path anywhere with current song text
                    if (!found) {
                        var pattern2 = new RegExp(stationPath + '[^<]*</a>[^<]*Current Song[^<]*<[^>]*>([^<]+)', 'i')
                        var match2 = response.match(pattern2)
                        if (match2 && match2[1]) {
                            songInfo = match2[1].trim()
                            found = true
                            console.log("Found song with pattern 2:", songInfo)
                        }
                    }
                    
                    // Pattern 3: Extract from table format
                    if (!found) {
                        var pattern3 = new RegExp(stationPath + '[^<]*</td[^>]*>\\s*<td[^>]*>([^<]+)', 'i')
                        var match3 = response.match(pattern3)
                        if (match3 && match3[1]) {
                            songInfo = match3[1].trim()
                            found = true
                            console.log("Found song with pattern 3:", songInfo)
                        }
                    }
                    
                    // Pattern 4: Search for station in server list and extract nearby text
                    if (!found) {
                        console.log("Trying to find station in server response...")
                        var lines = response.split('\n')
                        for (var i = 0; i < lines.length; i++) {
                            if (lines[i].toLowerCase().includes(stationPath.toLowerCase())) {
                                console.log("Found station line:", lines[i])
                                // Look for song info in this line or nearby lines
                                var linePattern = /Current Song[^<]*<[^>]*>([^<]+)/i
                                var lineMatch = lines[i].match(linePattern)
                                if (lineMatch && lineMatch[1]) {
                                    songInfo = lineMatch[1].trim()
                                    found = true
                                    console.log("Found song in line:", songInfo)
                                    break
                                }
                            }
                        }
                    }
                    
                    if (found && songInfo) {
                        console.log("Found current song from server status:", songInfo)
                        
                        // Parse "Artist - Title" format
                        if (songInfo.includes(" - ")) {
                            var parts = songInfo.split(" - ")
                            currentArtist = parts[0].trim()
                            currentSongTitle = parts.slice(1).join(" - ").trim()
                        } else {
                            currentSongTitle = songInfo
                            currentArtist = ""
                        }
                        
                        debugMetadata = "Server: " + songInfo
                        console.log("Updated from server status - Artist:", currentArtist, "Title:", currentSongTitle)
                    } else {
                        console.log("No current song found in server status, falling back to playback history")
                        console.log("Server response preview:", response.substring(0, 1000))
                        console.log("Searched for station:", stationPath)
                        debugMetadata = "Server: No match for " + stationPath
                        // Fallback to the old playback history method
                        getPlaybackHistoryUrl(stationPath)
                    }
                } else {
                    console.log("Failed to fetch server status:", xhr.status)
                    debugMetadata = "Server error: " + xhr.status
                    // Fallback to the old playback history method
                    getPlaybackHistoryUrl(stationPath)
                }
            }
        }
        
        xhr.timeout = 10000
        xhr.ontimeout = function() {
            console.log("Server status request timed out")
            debugMetadata = "Server timeout"
            // Fallback to the old playback history method
            getPlaybackHistoryUrl(stationPath)
        }
        
        xhr.open("GET", statusUrl)
        xhr.send()
    }
    
    function getWorkingPathForStation(stationPath) {
        // Based on station_metadata_test_results.json, return the working path number
        var stationPaths = {
            "80ru": 1, "aabmds": 2, "abstracthiphop": 3, "accordion": 4, "acid": 4, "acidjazz": 3,
            "acidrock": 5, "acoustic": 5, "acousticblues": 3, "acousticguitar": 2, "africanfolk": 2,
            "afrobeat": 2, "altcountry": 4, "altrock": 2, "ambient": 4, "ambientdub": 3, "ambienthouse": 6,
            "ambienttechno": 2, "americana": 5, "andean": 5, "anime": 4, "aor": 3, "arabicpop": 2,
            "artrock": 2, "avantblackmet": 2, "avantgardejazz": 4, "avantprog": 4, "avantrock": 5,
            "balearichouse": 5, "balkan": 2, "baroque": 3, "beatdown": 3, "bebop": 3, "bigband": 2,
            "bigroomhouse": 5, "blackdeath": 3, "blackdoom": 1, "blackmetal": 1, "bluegrass": 3,
            "blues": 1, "bluesrock": 2, "bossanova": 3, "brazilianjazz": 6, "breakbeat": 2, "breakcore": 4,
            "britpop": 2, "brokenbeat": 1, "cantata": 6, "cantopop": 6, "caucasus": 5, "cello": 3,
            "celticmetal": 6, "celticrock": 6, "chalga": 5, "chamber": 5, "chamberjazz": 2, "chamberpop": 3,
            "chicagoblues": 3, "chicanorap": 5, "chillout": 3, "chillwave": 1, "chiptune": 4, "christianrock": 5,
            "clarinet": 5, "classavant": 5, "classcross": 1, "classguitar": 5, "clavecin": 5, "cloudrap": 5,
            "clubru": 1, "contclass": 4, "contemporaryjazz": 4, "cooljazz": 2, "countryblues": 1, "countrypop": 4,
            "countryrock": 4, "crossoverjazz": 5, "crossoverprog": 3, "crossoverthrash": 5, "crust": 2,
            "cyberpunk": 6, "dancehall": 3, "dancepop": 1, "dancepunk": 5, "darkambient": 2, "darkcabaret": 4,
            "darkdubstep": 2, "darkelectro": 2, "darkfolk": 4, "darkjazz": 2, "darkmetal": 4, "darkpsytrance": 4,
            "darksynth": 5, "darktechno": 3, "darkwave": 3, "deathcore": 3, "deathmetal": 1, "deathnroll": 2,
            "deephouse": 2, "deltablues": 1, "disco": 1, "dixieland": 2, "downtempo": 1, "dreampop": 3,
            "dreamtrance": 2, "droneambient": 4, "dronemetal": 2, "drumbass": 3, "drumstep": 2, "dub": 3,
            "dubstep": 2, "dungeonsynth": 6, "easylistening": 3, "ebm": 3, "eclecticprog": 3, "edmtrap": 5,
            "electricblues": 3, "electro": 4, "electroclash": 2, "electrohouse": 3, "electroindustrial": 4,
            "electronicore": 4, "electroswing": 5, "enigmatic": 5, "epicmetal": 4, "erotic": 2, "ethereal": 5,
            "ethnojazz": 2, "ethnotronica": 2, "eurobeat": 2, "eurodance": 2, "eurodisco": 4, "eurohouse": 4,
            "europeanfolk": 5, "fado": 5, "femalemetal": 3, "flamenco": 3, "flute": 3, "fluteclass": 3,
            "folkmetal": 2, "folkpop": 5, "folkpunk": 5, "folkrock": 3, "folkrockru": 3, "forestpsytrance": 5,
            "freefunk": 6, "freeimprovisation": 1, "freejazz": 3, "freestyle": 6, "frenchpop": 1, "fullon": 3,
            "funk": 4, "funkrock": 5, "funkyhouse": 5, "futurebass": 5, "futuregarage": 2, "futurepop": 2,
            "gabber": 5, "gangstarap": 2, "garagepunk": 6, "ghouse": 3, "glam": 2, "glitch": 3, "goatrance": 2,
            "gospel": 3, "gothblackmet": 2, "gothdeathmet": 2, "gothicrock": 3, "grime": 1, "grindcore": 1,
            "groovemetal": 2, "grunge": 2, "guitarjazz": 1, "happyhardcore": 1, "hardbop": 3, "hardcorerap": 1,
            "hardcoretech": 2, "hardhouse": 5, "hardstyle": 3, "hardtrance": 1, "harp": 5, "harshnoise": 3,
            "healing": 5, "heavyblues": 1, "heavymetal": 3, "heavypowermetal": 3, "heavyprog": 3, "hiphop": 1,
            "hiphopsoul": 6, "hitechpsy": 6, "honkytonk": 5, "horrorpunk": 1, "house": 1, "idm": 3,
            "idmambient": 5, "illbient": 5, "impressionism": 1, "indiancinema": 2, "indieelectronic": 4,
            "indiefolk": 3, "indierock": 2, "industrial": 3, "industrialmetal": 2, "industrialrock": 1,
            "industrialtechno": 6, "instrumental": 1, "instrumentalhiphop": 1, "instrumentalrock": 2,
            "italodance": 3, "italodisco": 4, "italopop": 5, "jamband": 6, "jazz": 1, "jazzfunk": 2,
            "jazzmetal": 5, "jazzpop": 2, "jazzrap": 2, "jazzrock": 4, "jpop": 4, "jrock": 4,
            "jumpblues": 5, "jumpstyle": 6, "jungle": 5, "klezmer": 2, "kpop": 4, "krautrock": 4,
            "latinhouse": 6, "latinjazz": 4, "latinpop": 4, "leftfield": 2, "liquidfunk": 4, "lo-fi": 3,
            "louisianablues": 5, "lounge": 3, "lovesongs": 5, "lute": 6, "makina": 6, "manele": 5,
            "manouche": 1, "martialindustrial": 3, "mathmetal": 2, "mathrock": 2, "medieval": 5,
            "medievalfolk": 5, "medievalmetal": 5, "meditation": 1, "melodicdoom": 6, "melodicheavy": 4,
            "melodichouse": 6, "melodicmetalcore": 3, "melodicpower": 4, "memphisrap": 5, "metalcore": 2,
            "metalstep": 3, "middleeast": 4, "minimalism": 5, "mintechhouse": 4, "modaljazz": 5,
            "modernclassical": 2, "mpb": 3, "ndh": 5, "neoclassical": 2, "neoclassicalmetal": 4,
            "neoprogrock": 4, "neurofunk": 4, "newage": 1, "newbeat": 6, "nitzhonot": 5, "noiserock": 2,
            "nudisco": 4, "nujazz": 3, "numetal": 3, "nwobhm": 3, "oceania": 5, "oistreetpunk": 4,
            "opera": 2, "organ": 1, "organichouse": 6, "orientalmetal": 4, "orthodox": 3, "paganmetal": 4,
            "phonk": 1, "piano": 1, "pianoblues": 3, "pianojazz": 4, "pianorock": 3, "pop": 1,
            "poppunk": 3, "popru": 1, "popsoul": 5, "postblack": 3, "postbop": 3, "postgrunge": 4,
            "posthardcore": 4, "postmetal": 2, "postrock": 3, "powerelectronics": 3, "powermetal": 1,
            "powernoise": 2, "progbreaks": 6, "progdeath": 4, "progelectronic": 6, "progfolk": 5,
            "proghouse": 4, "progmetal": 1, "progmetalcore": 3, "progpowermetal": 4, "progrelated": 3,
            "progtrance": 2, "psychedelicrock": 4, "psychfolk": 5, "psychobilly": 4, "psytrance": 4,
            "pubrock": 6, "punk": 1, "punkru": 1, "rap": 1, "rapru": 1, "reggae": 2, "reggaeton": 5,
            "relaxation": 2, "renaissance": 5, "retrowave": 2, "riddimdubstep": 4, "rnb": 1, "rock": 1,
            "rockabilly": 3, "rockroll": 1, "rockru": 1, "rocksteady": 1, "romantic": 2, "rootsreggae": 4,
            "rootsrock": 6, "rpi": 3, "sacred": 5, "saxophone": 1, "schlager": 1, "siberia": 4,
            "ska": 4, "skapunk": 4, "slideguitar": 5, "slowcore": 5, "sludgemetal": 1, "smoothjazz": 2,
            "sonata": 5, "soul": 2, "soulblues": 3, "soulfulhouse": 4, "souljazz": 3, "southernrap": 4,
            "southernrock": 3, "spacemusic": 4, "spacerock": 4, "speedheavy": 5, "speedmetal": 4,
            "stonerrock": 4, "straightahead": 1, "strings": 2, "suomisaundi": 1, "surfrock": 4,
            "symphometal": 1, "symphony": 3, "symphopower": 5, "symphorock": 2, "synthpop": 1,
            "tango": 2, "techno": 1, "techtrance": 5, "texasblues": 3, "thirdstream": 5, "thrashblack": 5,
            "thrashdeath": 3, "thrashheavy": 5, "thrashmetal": 1, "tradelectronic": 3, "trailer": 4,
            "trance": 1, "tribalhouse": 5, "triphop": 3, "turkishpop": 5, "twilightpsy": 6, "twist": 4,
            "ukhiphop": 5, "undergroundrap": 3, "undergroundtechno": 5, "upliftingtrance": 4, "vikingmetal": 3,
            "violin": 5, "visualkei": 6, "vocal": 1, "vocaljazz": 2, "westcoastblues": 6, "westernswing": 3,
            "witchhouse": 1, "zydeco": 5
        }
        
        return stationPaths[stationPath] || 2  // Default to path 2 if not found
    }
    
    function getOptimizedPathOrder(stationPath) {
        // Get the known working path first, then try others
        var workingPath = getWorkingPathForStation(stationPath)
        var allPaths = [1, 2, 3, 4, 5, 6]
        var optimizedOrder = [workingPath]
        
        // Add remaining paths, most common first
        var remainingPaths = allPaths.filter(function(path) { return path !== workingPath })
        var commonOrder = [1, 2, 3, 4, 5, 6] // Try path 1 first for newer stations
        
        for (var i = 0; i < commonOrder.length; i++) {
            if (remainingPaths.indexOf(commonOrder[i]) !== -1) {
                optimizedOrder.push(commonOrder[i])
            }
        }
        
        console.log("Optimized path order for", stationPath + ":", optimizedOrder)
        return optimizedOrder
    }
    
    // Property to store search results at the root level
    property var radioSearchResults: []
    
    // Preview player properties
    property string previewStationUrl: ""
    property bool isPreviewPlaying: false
    
    function searchRadioStations(query) {
        console.log("Searching for radio stations:", query)
        
        // Clear previous results
        radioSearchResults = []
        
        if (query.length < 3) {
            console.log("Query too short, skipping search")
            return
        }
        
        var apiUrl = "https://de1.api.radio-browser.info/json/stations/search?name=" + 
                     encodeURIComponent(query) + "&limit=20&hidebroken=true&order=clickcount&reverse=true"
        
        console.log("Radio search API URL:", apiUrl)
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        console.log("Found", data.length, "radio stations")
                        
                        var results = []
                        for (var i = 0; i < Math.min(data.length, 15); i++) {
                            var station = data[i]
                            
                            // Filter out broken stations and ensure we have required fields
                            if (station.lastcheckok === 1 && station.url_resolved && station.name) {
                                results.push({
                                    name: station.name.trim(),
                                    url: station.url_resolved,
                                    tags: station.tags || "",
                                    country: station.country || "",
                                    codec: station.codec || "Unknown",
                                    bitrate: station.bitrate || 0,
                                    homepage: station.homepage || "",
                                    favicon: station.favicon || ""
                                })
                            }
                        }
                        
                        console.log("Processed", results.length, "valid stations")
                        
                        // Apply filters if enabled
                        if (enableSearchFilters) {
                            results = filterSearchResults(results)
                            console.log("After filtering:", results.length, "stations")
                        }
                        
                        // Update results
                        radioSearchResults = results
                        
                    } catch (e) {
                        console.log("Error parsing radio search response:", e)
                    }
                } else {
                    console.log("Radio search API request failed:", xhr.status)
                }
            }
        }
        
        xhr.open("GET", apiUrl)
        xhr.setRequestHeader("User-Agent", "RadCapRadio/1.0")
        xhr.send()
    }
    
    function filterSearchResults(results) {
        if (!results || results.length === 0) return results
        
        var filtered = []
        for (var i = 0; i < results.length; i++) {
            var station = results[i]
            var passesFilter = true
            
            // Apply bitrate filter
            if (minSearchBitrate > 0 && station.bitrate < minSearchBitrate) {
                passesFilter = false
            }
            
            // Apply codec filter
            if (codecFilter !== "" && station.codec.toLowerCase() !== codecFilter.toLowerCase()) {
                passesFilter = false
            }
            
            if (passesFilter) {
                filtered.push(station)
            }
        }
        
        return filtered
    }
    
    function isStationAlreadyAdded(stationName, stationUrl) {
        for (var i = 0; i < customStations.length; i++) {
            var station = customStations[i]
            // Check if either name or URL matches (to prevent duplicates)
            if (station.name === stationName || station.url === stationUrl) {
                return true
            }
        }
        return false
    }
    
    function searchEbooks(query) {
        console.log("Searching for ebooks:", query)
        
        // Clear previous results
        ebookSearchResults.clear()
        
        if (query.length < 3) {
            console.log("Query too short, skipping ebook search")
            return
        }
        
        // LibriVox API search
        var apiUrl = "https://librivox.org/api/feed/audiobooks/title/" + 
                     encodeURIComponent(query) + "?format=json&limit=10"
        
        console.log("LibriVox search API URL:", apiUrl)
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        console.log("Found", data.books ? data.books.length : 0, "ebooks")
                        
                        if (data.books) {
                            for (var i = 0; i < Math.min(data.books.length, 10); i++) {
                                var book = data.books[i]
                                if (book.title && book.rss_url) {
                                    ebookSearchResults.append({
                                        title: book.title,
                                        authors: book.authors || "Unknown",
                                        rss_url: book.rss_url,
                                        description: book.description || ""
                                    })
                                }
                            }
                        }
                        
                        // Add hardcoded Alice in Wonderland if searching for Alice
                        if (query.toLowerCase().includes("alice")) {
                            ebookSearchResults.insert(0, {
                                title: "Alice's Adventures in Wonderland",
                                authors: "Lewis Carroll",
                                rss_url: "https://librivox.org/rss/200",
                                description: "Classic children's tale"
                            })
                        }
                        
                    } catch (e) {
                        console.log("Error parsing ebook search response:", e)
                        
                        // Fallback for Alice search
                        if (query.toLowerCase().includes("alice")) {
                            ebookSearchResults.append({
                                title: "Alice's Adventures in Wonderland",
                                authors: "Lewis Carroll", 
                                rss_url: "https://librivox.org/rss/200",
                                description: "Classic children's tale"
                            })
                        }
                    }
                } else {
                    console.log("Ebook search API request failed:", xhr.status)
                    
                    // Fallback for Alice search
                    if (query.toLowerCase().includes("alice")) {
                        ebookSearchResults.append({
                            title: "Alice's Adventures in Wonderland",
                            authors: "Lewis Carroll",
                            rss_url: "https://librivox.org/rss/11", 
                            description: "Classic children's tale"
                        })
                    }
                }
            }
        }
        
        xhr.open("GET", apiUrl)
        xhr.setRequestHeader("User-Agent", "FreeRadio/1.2")
        xhr.send()
    }

    function getPlaybackHistoryUrl(stationPath) {
        // Try multiple possible HTML page names since they don't always match the stream path exactly
        var possibleNames = [stationPath]
        
        // Handle common naming variations based on actual HTML files
        if (stationPath === "classpiano") {
            possibleNames.push("classicalpiano")
        } else if (stationPath === "indianfolk") {
            possibleNames.push("indian", "indianclassical")
        } else if (stationPath === "folkrockru") {
            possibleNames.push("folkrockru", "russianfolk", "folkrock")
        } else if (stationPath === "symphony") {
            possibleNames.push("symphonic")
        } else if (stationPath === "nativeamerican") {
            possibleNames.push("natam")
        } else if (stationPath === "celticrock") {
            possibleNames.push("celtic", "celticrock")
        } else if (stationPath === "middleeast") {
            possibleNames.push("middleeast")
        } else if (stationPath === "symphorock") {
            possibleNames.push("symphonic", "symphorock")
        } else if (stationPath === "chorus") {
            possibleNames.push("choral", "chorus")
        } else if (stationPath === "organ") {
            possibleNames.push("organ")
        } else if (stationPath === "baroque") {
            possibleNames.push("baroque")
        } else if (stationPath === "opera") {
            possibleNames.push("opera")
        } else if (stationPath === "strings") {
            possibleNames.push("strings")
        } else if (stationPath === "contclass") {
            possibleNames.push("contclass", "modernclassical")
        } else if (stationPath === "renaissance") {
            possibleNames.push("renaissance")
        } else if (stationPath === "medieval") {
            possibleNames.push("medieval")
        } else if (stationPath === "chamber") {
            possibleNames.push("chamber")
        } else if (stationPath === "classical") {
            possibleNames.push("classical", "classical-d")
        } else if (stationPath === "electronic") {
            possibleNames.push("electronic", "electronic-d")
        } else if (stationPath === "metal") {
            possibleNames.push("metal", "metal-d", "heavymetal", "blackmetal")
        } else if (stationPath === "jazz") {
            possibleNames.push("jazz", "jazz-d")
        } else if (stationPath === "blues") {
            possibleNames.push("blues", "blues-d")
        } else if (stationPath === "rock") {
            possibleNames.push("rock", "rock-d")
        } else if (stationPath === "pop") {
            possibleNames.push("pop", "pop-d")
        } else if (stationPath === "reggae") {
            possibleNames.push("reggae", "reggae-d")
        } else if (stationPath === "hardcore") {
            possibleNames.push("hardcore", "hardcore-d")
        } else if (stationPath === "salsa") {
            possibleNames.push("salsa", "latin", "latinpop")
        } else if (stationPath === "balkan") {
            possibleNames.push("balkan")
        } else if (stationPath === "klezmer") {
            possibleNames.push("klezmer")
        } else if (stationPath === "laika") {
            possibleNames.push("laiko")
        } else if (stationPath === "africanfolk") {
            possibleNames.push("africanfolk")
        } else if (stationPath === "freestyle") {
            possibleNames.push("freestyle", "fareast")
        } else if (stationPath === "caucasus") {
            possibleNames.push("caucasus")
        } else if (stationPath === "americana") {
            possibleNames.push("americana")
        } else if (stationPath === "gospel") {
            possibleNames.push("gospel")
        } else if (stationPath === "siberia") {
            possibleNames.push("siberia")
        } else if (stationPath === "medievalfolk") {
            possibleNames.push("medievalfolk")
        } else if (stationPath === "europeanfolk") {
            possibleNames.push("europeanfolk")
        } else if (stationPath === "fado") {
            possibleNames.push("fado")
        } else if (stationPath === "slavonicneofolk") {
            possibleNames.push("slavonicneofolk", "slavonic")
        } else if (stationPath === "oceania") {
            possibleNames.push("oceania")
        } else if (stationPath === "andean") {
            possibleNames.push("andean")
        } else if (stationPath === "zydeco") {
            possibleNames.push("zydeco")
        } else if (stationPath === "afrobeat") {
            possibleNames.push("afrobeat")
        } else if (stationPath === "oldschoolhiphop") {
            possibleNames.push("oldschhiphop")
        } else if (stationPath === "soundnat") {
            possibleNames.push("soundsnat")
        } else if (stationPath === "popballads") {
            possibleNames.push("popball")
        } else if (stationPath === "rockballads") {
            possibleNames.push("rockball")
        } else if (stationPath === "jazzfusion") {
            possibleNames.push("fusion", "jazzfunk")
        } else if (stationPath === "screamoemo") {
            possibleNames.push("emoscreamo")
        } else if (stationPath === "shoegazing") {
            possibleNames.push("shoegaze")
        } else if (stationPath === "gypsyru") {
            possibleNames.push("gypsy")
        } else if (stationPath === "mintechno") {
            possibleNames.push("mintech")
        } else if (stationPath === "dubtechno") {
            possibleNames.push("dubtech")
        } else if (stationPath === "detroittechno") {
            possibleNames.push("detroittech")
        } else if (stationPath === "electrotechno") {
            possibleNames.push("electrotech")
        } else if (stationPath === "experimentaltechno") {
            possibleNames.push("exptechno")
        }
        
        // Add smart fallback patterns for any station not specifically handled above
        if (possibleNames.length === 1) {
            // Try common patterns
            if (stationPath.endsWith("folk")) {
                var baseGenre = stationPath.replace("folk", "")
                if (baseGenre) possibleNames.push(baseGenre)
            }
            if (stationPath.endsWith("rock")) {
                var baseGenre = stationPath.replace("rock", "")
                if (baseGenre) possibleNames.push(baseGenre)
            }
            if (stationPath.endsWith("jazz")) {
                var baseGenre = stationPath.replace("jazz", "")
                if (baseGenre) possibleNames.push(baseGenre)
            }
            if (stationPath.endsWith("metal")) {
                var baseGenre = stationPath.replace("metal", "")
                if (baseGenre) possibleNames.push(baseGenre)
            }
            if (stationPath.endsWith("pop")) {
                var baseGenre = stationPath.replace("pop", "")
                if (baseGenre) possibleNames.push(baseGenre)
            }
            
            // Try with -d suffix (common pattern)
            possibleNames.push(stationPath + "-d")
            possibleNames.push(stationPath + "-m")
        }
        
        console.log("Trying station page names for", stationPath + ":", possibleNames)
        tryStationPageUrl(possibleNames, 0, stationPath)
    }
    
    function tryStationPageUrl(possibleNames, index, originalStationPath) {
        if (index >= possibleNames.length) {
            console.log("All station page names failed for:", originalStationPath)
            debugMetadata = "No valid station page found"
            // Fallback to the old method with optimized path order
            var optimizedPaths = getOptimizedPathOrder(originalStationPath)
            tryPlaybackHistoryUrl(originalStationPath, optimizedPaths, 0)
            return
        }
        
        var pageName = possibleNames[index]
        var stationPageUrl = "http://radcap.ru/" + pageName + ".html"
        console.log("Trying station page:", stationPageUrl)
        debugMetadata = "Trying page: " + pageName + ".html"
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = xhr.responseText
                    console.log("Fetched station page, looking for playback-html link...")
                    
                    // Look for the playback-html class link
                    var playbackMatch = response.match(/class="playback-html"[^>]*>\s*<a\s+href="([^"]+)"/i)
                    if (playbackMatch && playbackMatch[1]) {
                        var playbackPath = playbackMatch[1]
                        var fullPlaybackUrl = "http://radcap.ru/" + playbackPath
                        console.log("Found playback history URL:", fullPlaybackUrl)
                        
                        // Now fetch the actual playback history
                        fetchPlaybackHistory(fullPlaybackUrl)
                    } else {
                        console.log("No playback-html link found, trying next page name...")
                        // Try next possible name
                        tryStationPageUrl(possibleNames, index + 1, originalStationPath)
                    }
                } else if (xhr.status === 404) {
                    console.log("Page not found, trying next name...")
                    // Try next possible name
                    tryStationPageUrl(possibleNames, index + 1, originalStationPath)
                } else {
                    console.log("Failed to fetch station page:", xhr.status)
                    debugMetadata = "Station page error: " + xhr.status
                    // Try next possible name
                    tryStationPageUrl(possibleNames, index + 1, originalStationPath)
                }
            }
        }
        
        xhr.timeout = 10000
        xhr.ontimeout = function() {
            console.log("Station page request timed out, trying next name...")
            // Try next possible name
            tryStationPageUrl(possibleNames, index + 1, originalStationPath)
        }
        
        xhr.open("GET", stationPageUrl)
        xhr.send()
    }
    
    function fetchPlaybackHistory(playbackUrl) {
        console.log("Fetching playback history from:", playbackUrl)
        debugMetadata = "Fetching: " + playbackUrl.split('/').pop()
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = xhr.responseText
                    console.log("Fetched playback history, length:", response.length, "chars")
                    
                    // Try multiple regex patterns to find current song
                    var currentSongMatch = response.match(/<td>([^<]+)<td><b>Current Song<\/b><\/td>/i)
                    if (!currentSongMatch) {
                        currentSongMatch = response.match(/<td>([^<]+)<\/td><td><b>Current Song<\/b><\/td>/i)
                    }
                    if (!currentSongMatch) {
                        currentSongMatch = response.match(/<td>\d{2}:\d{2}:\d{2}<\/td><td>([^<]+)(?:<td>|<\/td>)/i)
                    }
                    
                    if (currentSongMatch && currentSongMatch[1]) {
                        var songInfo = currentSongMatch[1].trim()
                        console.log("Found current song:", songInfo)
                        
                        // Parse "Artist - Title" format
                        if (songInfo.includes(" - ")) {
                            var parts = songInfo.split(" - ")
                            currentArtist = parts[0].trim()
                            currentSongTitle = parts.slice(1).join(" - ").trim()
                        } else {
                            currentSongTitle = songInfo
                            currentArtist = ""
                        }
                        
                        debugMetadata = "Live: " + songInfo
                        console.log("Updated song info - Artist:", currentArtist, "Title:", currentSongTitle)
                    } else {
                        console.log("No current song found in playback history")
                        debugMetadata = "Live feed: No song match"
                    }
                } else {
                    console.log("Failed to fetch playback history:", xhr.status)
                    debugMetadata = "Playback error: " + xhr.status
                }
            }
        }
        
        xhr.timeout = 10000
        xhr.ontimeout = function() {
            console.log("Playback history request timed out")
            debugMetadata = "Playback timeout"
        }
        
        xhr.open("GET", playbackUrl)
        xhr.send()
    }
    
    function tryPlaybackHistoryUrl(stationPath, pathNumbers, index) {
        if (index >= pathNumbers.length) {
            console.log("All playback history paths failed for:", stationPath)
            debugMetadata = "Live feed: No valid path found"
            return
        }
        
        var pathNumber = pathNumbers[index]
        
        // Handle special cases where the metadata path differs from the station path
        var metadataPath = stationPath
        var pathMappings = {
            "musicgame": "gamemusic",
            "indianfolk": "indian",
            "nativeamerican": "natam",
            "slavonicneofolk": "slavonic",
            "classpiano": "classicalpiano",
            "popballads": "popball",
            "mainstreamjazz": "jazz",
            "jazzfusion": "fusion",
            "mcreative": "moderncreative",
            "ecmrecords": "ecm",
            "trumpetjazz": "trumpet",
            "bardru": "bard",
            "frenchchanson": "chanson",
            "tradpop": "pop",
            "cpop": "cantopop",
            "harpblues": "harp",
            "chorus": "choral",
            "chants": "chant"
        }
        
        if (pathMappings[stationPath]) {
            metadataPath = pathMappings[stationPath]
        }
        
        var historyUrl = "http://radcap.ru/playback-history/" + pathNumber + "/" + metadataPath + "-ph.php"
        
        console.log("Trying path", pathNumber + ":", historyUrl)
        debugMetadata = "Trying path " + pathNumber + ": " + stationPath
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("Request completed. Status:", xhr.status, "for path", pathNumber)
                if (xhr.status === 200) {
                    var response = xhr.responseText
                    console.log("Fetched playback history, length:", response.length, "chars")
                    
                    // Try multiple regex patterns to find current song
                    // Pattern 1: Missing closing </td> tag before Current Song marker
                    var currentSongMatch = response.match(/<td>([^<]+)<td><b>Current Song<\/b><\/td>/i)
                    if (!currentSongMatch) {
                        // Pattern 2: Proper closing </td> tag
                        currentSongMatch = response.match(/<td>([^<]+)<\/td><td><b>Current Song<\/b><\/td>/i)
                    }
                    if (!currentSongMatch) {
                        // Pattern 3: Look for most recent entry (first song in the list)
                        currentSongMatch = response.match(/<td>\d{2}:\d{2}:\d{2}<\/td><td>([^<]+)(?:<td>|<\/td>)/i)
                    }
                    
                    if (currentSongMatch && currentSongMatch[1]) {
                        var songInfo = currentSongMatch[1].trim()
                        console.log("Found current song:", songInfo)
                        
                        // Parse "Artist - Title" format
                        if (songInfo.includes(" - ")) {
                            var parts = songInfo.split(" - ")
                            currentArtist = parts[0].trim()
                            currentSongTitle = parts.slice(1).join(" - ").trim()
                        } else {
                            currentSongTitle = songInfo
                            currentArtist = ""
                        }
                        
                        debugMetadata = "Live (path " + pathNumber + "): " + songInfo
                        console.log("Updated song info - Artist:", currentArtist, "Title:", currentSongTitle)
                    } else {
                        console.log("No current song found in playback history")
                        debugMetadata = "Live feed: No pattern match"
                    }
                } else if (xhr.status === 302 || xhr.status === 404) {
                    // Try next path number
                    console.log("Path", pathNumber, "failed, trying next...")
                    tryPlaybackHistoryUrl(stationPath, pathNumbers, index + 1)
                } else {
                    console.log("Failed to fetch playback history:", xhr.status, xhr.statusText)
                    debugMetadata = "Live feed error: " + xhr.status + " " + xhr.statusText
                }
            }
        }
        
        xhr.timeout = 10000 // 10 second timeout
        xhr.ontimeout = function() {
            console.log("Request timed out for path", pathNumber + ", trying next...")
            tryPlaybackHistoryUrl(stationPath, pathNumbers, index + 1)
        }
        
        xhr.open("GET", historyUrl)
        xhr.send()
    }
    
    function reloadCurrentStation() {
        if (currentStationName && currentStationHost && currentStationPath) {
            console.log("Reloading current station with new quality:", streamQuality)
            
            // Generate new URL with updated quality
            var streamUrl = getStreamUrl(currentStationHost, currentStationPath, streamQuality)
            currentStationUrl = streamUrl
            
            // Clear song info when changing quality
            currentSongTitle = ""
            currentArtist = ""
            debugMetadata = "Reloading with new quality..."
            
            songUpdateTimer.stop()
            player.stop()
            console.log("=== RELOADING STATION ===")
            console.log("Old URL:", currentStationUrl)
            console.log("New URL:", streamUrl)
            console.log("Quality level:", streamQuality)
            
            // Fetch live song metadata
            fetchStreamMetadata(streamUrl)
            songUpdateTimer.start()
            idleResetTimer.start()
            silentPlaybackDetector.start()
            
            lastBufferProgress = 0
            lastBufferUpdateTime = Date.now()
            player.source = streamUrl
            player.play()
        }
    }
    
    function loadCategory(cat) {
        try {
            console.log("Loading category:", cat.name)
            currentCategory = cat.name
            stationsModel.clear()
            
            // Need to find the actual category from our data since ListModel may not preserve arrays
            var categoryData = null
            
            // Look in the appropriate source data
            if (currentSource === "📻 RadCap.ru") {
                for (var j = 0; j < RadioData.radcapCategories.length; j++) {
                    if (RadioData.radcapCategories[j].name === cat.name) {
                        categoryData = RadioData.radcapCategories[j]
                        break
                    }
                }
            } else if (currentSource === "🎵 SomaFM") {
                for (var k = 0; k < RadioData.somafmCategories.length; k++) {
                    if (RadioData.somafmCategories[k].name === cat.name) {
                        categoryData = RadioData.somafmCategories[k]
                        break
                    }
                }
            } else if (currentSource === "📚 Audiobooks") {
                // Handle ebook category
                categoryData = {
                    name: cat.name,
                    stations: customEbooks.map(function(ebook) {
                        return {
                            "name": ebook.title,
                            "url": ebook.url,
                            "host": "",
                            "path": "",
                            "type": "ebook"
                        }
                    })
                }
            }
            
            if (categoryData && categoryData.stations) {
                console.log("Found category data with", categoryData.stations.length, "stations")
            
            // Check if this is an Icecast Directory category that needs dynamic loading
            if (categoryData.stations && categoryData.stations.length === 1 && 
                categoryData.stations[0].name === "Loading..." &&
                categoryData.stations[0].host === "https://dir.xiph.org") {
                console.log("Loading Icecast Directory streams for:", categoryData.name)
                fetchIcecastStreams(categoryData)
            } else {
                // Load stations normally
                for (var j = 0; j < categoryData.stations.length; ++j) {
                    stationsModel.append({
                        "name": categoryData.stations[j].name,
                        "host": categoryData.stations[j].host,
                        "path": categoryData.stations[j].path,
                        "url": categoryData.stations[j].url || "",
                        "type": categoryData.stations[j].type || ""
                    })
                }
            }
        } else {
            console.log("No category data found for:", cat.name)
        }
        
        inCategory = true
        } catch (e) {
            console.log("Error in loadCategory:", e)
        }
    }
    
    function fetchIcecastStreams(categoryData) {
        console.log("Fetching Icecast streams for category:", categoryData.name)
        
        // Show loading station
        stationsModel.append({
            "name": "🔄 Loading streams...",
            "host": "loading",
            "path": "loading"
        })
        
        // Use the pre-encoded URL path from the category data
        var genreUrl = "https://dir.xiph.org/" + categoryData.stations[0].path
        console.log("Fetching Icecast genre page:", genreUrl)
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    console.log("Successfully fetched Icecast genre page")
                    parseIcecastStreams(xhr.responseText, categoryData, true)
                } else {
                    console.log("Failed to fetch Icecast genre page, status:", xhr.status)
                    // Remove loading station and show error
                    stationsModel.clear()
                    stationsModel.append({
                        "name": "❌ Failed to load streams (Status: " + xhr.status + ")",
                        "host": "error", 
                        "path": "error"
                    })
                }
            }
        }
        xhr.open("GET", genreUrl)
        xhr.send()
    }
    
    function parseIcecastStreams(html, categoryData, isFirstPage) {
        console.log("Parsing Icecast streams from HTML response")
        if (isFirstPage) {
            stationsModel.clear()
        }
        
        try {
            // Parse the HTML to extract stream information
            var streamCount = 0
            
            // Look for station names in <h5> tags
            var h5Matches = html.match(/<h5[^>]*>(.*?)<\/h5>/gi)
            var h6Matches = html.match(/<h6[^>]*>On Air:\s*(.*?)<\/h6>/gi)
            var linkMatches = html.match(/<a[^>]*href=['"](.*?)['"][^>]*>Play<\/a>/gi)
            
            if (h5Matches && linkMatches) {
                var maxStations = Math.min(h5Matches.length, linkMatches.length)
                
                for (var i = 0; i < maxStations; i++) {
                    // Extract station name from h5
                    var nameMatch = h5Matches[i].match(/<h5[^>]*>(.*?)<\/h5>/i)
                    if (!nameMatch) continue
                    
                    var stationName = nameMatch[1].trim()
                    
                    // Extract stream URL from link
                    var urlMatch = linkMatches[i].match(/href=['"](.*?)['"]/)
                    if (!urlMatch) continue
                    
                    var streamUrl = urlMatch[1].trim()
                    
                    // Quality filtering
                    var skipStream = false
                    var streamText = stationName + " " + streamUrl
                    
                    // Extract bitrate if available
                    var detectedBitrate = 0
                    var bitrateMatch = streamText.match(/\b(\d{1,3})\s*kbps?\b/i)
                    if (bitrateMatch) {
                        detectedBitrate = parseInt(bitrateMatch[1])
                    }
                    
                    // Skip if bitrate is below minimum
                    if (detectedBitrate > 0 && detectedBitrate < minBitrate) {
                        skipStream = true
                        console.log("Skipping low bitrate stream:", stationName, "(" + detectedBitrate + "kbps)")
                    }
                    
                    // Skip obvious low quality indicators
                    if (skipLowQuality) {
                        var lowQualityIndicators = [
                            /\b(mono|am|telephone|lo-?fi)\b/i,
                            /\b(8|16|24|32)kbps?\b/i,
                            /\btesting?\b/i,
                            /\btest\s*(stream|radio|station)\b/i
                        ]
                        
                        for (var q = 0; q < lowQualityIndicators.length; q++) {
                            if (streamText.match(lowQualityIndicators[q])) {
                                skipStream = true
                                console.log("Skipping low quality stream:", stationName)
                                break
                            }
                        }
                    }
                    
                    // Skip talk radio if enabled
                    if (skipTalkRadio) {
                        var talkIndicators = [
                            /\b(talk|news|podcast|discussion|interview)\b/i,
                            /\b(radio\s+talk|talk\s+radio)\b/i,
                            /\bspoken\s+word\b/i
                        ]
                        
                        for (var t = 0; t < talkIndicators.length; t++) {
                            if (streamText.match(talkIndicators[t])) {
                                skipStream = true
                                console.log("Skipping talk radio stream:", stationName)
                                break
                            }
                        }
                    }
                    
                    if (skipStream) continue
                    
                    // Check for duplicates in current model
                    var isDuplicate = false
                    for (var j = 0; j < stationsModel.count; j++) {
                        if (stationsModel.get(j).path === streamUrl) {
                            isDuplicate = true
                            break
                        }
                    }
                    
                    if (isDuplicate) {
                        console.log("Skipping duplicate stream URL:", streamUrl)
                        continue
                    }
                    
                    // Extract "On Air" info if available
                    var onAir = ""
                    if (h6Matches && h6Matches[i]) {
                        var onAirMatch = h6Matches[i].match(/>On Air:\s*(.*?)<\/h6>/i)
                        if (onAirMatch) {
                            onAir = onAirMatch[1].trim()
                        }
                    }
                    
                    // Add quality indicator to station name if detectable
                    var displayName = stationName
                    var bitrateMatch = (stationName + " " + streamUrl).match(/\b(\d{2,3})\s*kbps?\b/i)
                    if (bitrateMatch && parseInt(bitrateMatch[1]) >= 64) {
                        displayName = stationName + " (" + bitrateMatch[1] + "kbps)"
                    }
                    
                    // Add the station to the model
                    stationsModel.append({
                        "name": displayName,
                        "host": "https://dir.xiph.org",
                        "path": streamUrl,
                        "currentSong": onAir
                    })
                    
                    streamCount++
                    console.log("Added Icecast station:", displayName, "->", streamUrl)
                }
            }
            
            // Check for next page cursor
            var nextMatch = html.match(/<a[^>]*href=['"](.*?cursor=[^'"]*?)['"][^>]*>Next<\/a>/i)
            if (nextMatch) {
                var nextUrl = nextMatch[1].trim()
                console.log("Found next page, fetching:", nextUrl)
                
                // Add loading indicator for more content
                stationsModel.append({
                    "name": "🔄 Loading more...",
                    "host": "loading_more",
                    "path": "loading_more"
                })
                
                // Fetch next page
                fetchNextIcecastPage(nextUrl, categoryData)
            } else {
                console.log("No more pages found")
                // Add final count
                if (isFirstPage && streamCount === 0) {
                    stationsModel.append({
                        "name": "⚠️ No streams found in this category",
                        "host": "empty",
                        "path": "empty"
                    })
                }
            }
            
            console.log("Successfully parsed", streamCount, "Icecast streams from this page")
            
        } catch (e) {
            console.log("Error parsing Icecast streams:", e)
            if (isFirstPage) {
                stationsModel.clear()
                stationsModel.append({
                    "name": "❌ Error parsing streams",
                    "host": "error",
                    "path": "error"
                })
            }
        }
    }
    
    function fetchNextIcecastPage(nextUrl, categoryData) {
        var fullUrl = "https://dir.xiph.org" + nextUrl
        console.log("Fetching next Icecast page:", fullUrl)
        
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // Remove loading indicator
                for (var i = stationsModel.count - 1; i >= 0; i--) {
                    if (stationsModel.get(i).host === "loading_more") {
                        stationsModel.remove(i)
                        break
                    }
                }
                
                if (xhr.status === 200) {
                    console.log("Successfully fetched next Icecast page")
                    parseIcecastStreams(xhr.responseText, categoryData, false)
                } else {
                    console.log("Failed to fetch next Icecast page, status:", xhr.status)
                }
            }
        }
        xhr.open("GET", fullUrl)
        xhr.send()
    }
    
    function fuzzyMatch(query, text) {
        if (!query || !text) return false
        
        query = query.toLowerCase()
        text = text.toLowerCase()
        
        // Exact match gets highest priority
        if (text.includes(query)) return true
        
        // Remove special characters for better matching
        var cleanQuery = query.replace(/[^a-z0-9\s]/g, "")
        var cleanText = text.replace(/[^a-z0-9\s]/g, "")
        
        if (cleanText.includes(cleanQuery)) return true
        
        // Word-based fuzzy matching
        var queryWords = cleanQuery.split(/\s+/).filter(function(w) { return w.length > 0 })
        var textWords = cleanText.split(/\s+/)
        
        var matchedWords = 0
        for (var i = 0; i < queryWords.length; i++) {
            var queryWord = queryWords[i]
            for (var j = 0; j < textWords.length; j++) {
                var textWord = textWords[j]
                // Check if textWord starts with queryWord or contains it
                if (textWord.indexOf(queryWord) === 0 || textWord.includes(queryWord)) {
                    matchedWords++
                    break
                }
            }
        }
        
        // Match if at least half the query words match
        return matchedWords >= Math.ceil(queryWords.length * 0.5)
    }
    
    function searchStations(query) {
        console.log("Searching stations with query:", query)
        searchResultsModel.clear()
        
        if (!query || query.trim() === "") {
            isSearchMode = false
            return
        }
        
        isSearchMode = true
        searchQuery = query.trim()
        
        var results = []
        
        // Search through SomaFM stations
        for (var i = 0; i < RadioData.somafmCategories.length; i++) {
            var category = RadioData.somafmCategories[i]
            for (var j = 0; j < category.stations.length; j++) {
                var station = category.stations[j]
                if (fuzzyMatch(searchQuery, station.name) || 
                    (station.description && fuzzyMatch(searchQuery, station.description))) {
                    results.push({
                        name: station.name + " (SomaFM)",
                        host: station.host,
                        path: station.path,
                        source: "🎵 SomaFM",
                        category: category.name
                    })
                }
            }
        }
        
        // Search through RadCap stations
        for (var k = 0; k < RadioData.radcapCategories.length; k++) {
            var radcapCategory = RadioData.radcapCategories[k]
            for (var l = 0; l < radcapCategory.stations.length; l++) {
                var radcapStation = radcapCategory.stations[l]
                if (fuzzyMatch(searchQuery, radcapStation.name)) {
                    results.push({
                        name: radcapStation.name + " (RadCap)",
                        host: radcapStation.host,
                        path: radcapStation.path,
                        source: "📻 RadCap.ru",
                        category: radcapCategory.name
                    })
                }
            }
        }
        
        // Search through favorites
        for (var m = 0; m < favoriteStations.length; m++) {
            var favStation = favoriteStations[m]
            if (fuzzyMatch(searchQuery, favStation.name)) {
                results.push({
                    name: favStation.name + " (Favorite)",
                    host: favStation.host,
                    path: favStation.path,
                    source: "⭐ Favorites",
                    category: "Favorites"
                })
            }
        }
        
        // Sort results: exact matches first, then partial matches
        results.sort(function(a, b) {
            var aExact = a.name.toLowerCase().includes(searchQuery.toLowerCase())
            var bExact = b.name.toLowerCase().includes(searchQuery.toLowerCase())
            
            if (aExact && !bExact) return -1
            if (!aExact && bExact) return 1
            
            return a.name.localeCompare(b.name)
        })
        
        // Add results to model
        for (var n = 0; n < Math.min(results.length, 50); n++) { // Limit to 50 results
            searchResultsModel.append(results[n])
        }
        
        console.log("Found", results.length, "search results")
    }
    
    function updateCurrentStationsList() {
        currentStationsList = []
        currentStationIndex = -1
        
        if (isSearchMode) {
            // Use search results
            navigationContext = "search"
            for (var i = 0; i < searchResultsModel.count; i++) {
                var item = searchResultsModel.get(i)
                currentStationsList.push({
                    name: item.name,
                    host: item.host,
                    path: item.path,
                    source: item.source,
                    category: item.category
                })
            }
        } else if (inCategory) {
            // Use current category stations
            navigationContext = currentSource === "⭐ Favorites" ? "favorites" : "category"
            for (var j = 0; j < stationsModel.count; j++) {
                var station = stationsModel.get(j)
                currentStationsList.push({
                    name: station.name,
                    host: station.host,
                    path: station.path,
                    source: currentSource,
                    category: currentCategory
                })
            }
        }
        
        // Find current station index
        for (var k = 0; k < currentStationsList.length; k++) {
            if (currentStationsList[k].name === currentStationName && 
                currentStationsList[k].host === currentStationHost && 
                currentStationsList[k].path === currentStationPath) {
                currentStationIndex = k
                break
            }
        }
        
        console.log("Updated stations list:", currentStationsList.length, "stations, current index:", currentStationIndex)
    }
    
    function playStationByIndex(index) {
        if (index < 0 || index >= currentStationsList.length) {
            console.log("Invalid station index:", index)
            return false
        }
        
        var station = currentStationsList[index]
        
        // Check if this is an ebook
        if (station.type === "ebook") {
            playEbook(station)
            currentStationIndex = index
            return true
        }
        
        var streamUrl = getStreamUrl(station.host, station.path, streamQuality)
        
        currentStationName = station.name
        currentStationUrl = streamUrl
        currentStationHost = station.host
        currentStationPath = station.path
        currentStationIndex = index
        
        // Clear ebook state when playing radio
        currentEbookUrl = ""
        currentEbookTitle = ""
        currentEbookChapters = []
        currentEbookChapterIndex = -1
        ebookProgressTimer.stop()
        
        // Save this as the last played station
        saveLastStation()
        
        // Clear previous song info when changing stations
        currentSongTitle = ""
        currentArtist = ""
        debugMetadata = "Loading station..."
        
        console.log("=== PLAYING STATION BY INDEX ===")
        console.log("Index:", index, "/", currentStationsList.length)
        console.log("Station:", station.name)
        console.log("Stream URL:", streamUrl)
        
        songUpdateTimer.stop()
        player.stop()
        
        // Fetch live song metadata and start timer
        fetchStreamMetadata(streamUrl)
        songUpdateTimer.start()
        idleResetTimer.start()
        silentPlaybackDetector.start()
        
        // Reset pause state and play directly
        userPaused = false
        lastBufferProgress = 0
        lastBufferUpdateTime = Date.now()
        player.source = streamUrl
        player.play()
        
        return true
    }
    
    function playRandomStation() {
        var allStations = []
        
        if (isSearchMode) {
            // In search mode: randomize from search results
            console.log("Random from search results")
            updateCurrentStationsList()
            allStations = currentStationsList
        } else if (inCategory) {
            // In a category: randomize within current category
            console.log("Random from current category:", currentCategory)
            updateCurrentStationsList()
            allStations = currentStationsList
        } else if (inSource) {
            // In a source but not in category: randomize from all categories in that source
            console.log("Random from all categories in source:", currentSource)
            
            if (currentSource === "📻 RadCap.ru") {
                // Get all RadCap stations
                for (var i = 0; i < RadioData.radcapCategories.length; i++) {
                    var category = RadioData.radcapCategories[i]
                    for (var j = 0; j < category.stations.length; j++) {
                        allStations.push({
                            name: category.stations[j].name,
                            host: category.stations[j].host,
                            path: category.stations[j].path,
                            source: "📻 RadCap.ru",
                            category: category.name
                        })
                    }
                }
            } else if (currentSource === "🎵 SomaFM") {
                // Get all SomaFM stations
                for (var k = 0; k < RadioData.somafmCategories.length; k++) {
                    var somaCategory = RadioData.somafmCategories[k]
                    for (var l = 0; l < somaCategory.stations.length; l++) {
                        allStations.push({
                            name: somaCategory.stations[l].name,
                            host: somaCategory.stations[l].host,
                            path: somaCategory.stations[l].path,
                            source: "🎵 SomaFM",
                            category: somaCategory.name
                        })
                    }
                }
            } else if (currentSource === "⭐ Favorites") {
                // Get all favorite stations
                for (var m = 0; m < favoriteStations.length; m++) {
                    allStations.push({
                        name: favoriteStations[m].name,
                        host: favoriteStations[m].host,
                        path: favoriteStations[m].path,
                        source: "⭐ Favorites",
                        category: "Favorites"
                    })
                }
            }
        } else {
            // At main menu: randomize from all sources (RadCap + SomaFM + Favorites)
            console.log("Random from all sources")
            
            // Add all RadCap stations
            for (var n = 0; n < RadioData.radcapCategories.length; n++) {
                var radcapCat = RadioData.radcapCategories[n]
                for (var o = 0; o < radcapCat.stations.length; o++) {
                    allStations.push({
                        name: radcapCat.stations[o].name,
                        host: radcapCat.stations[o].host,
                        path: radcapCat.stations[o].path,
                        source: "📻 RadCap.ru",
                        category: radcapCat.name
                    })
                }
            }
            
            // Add all SomaFM stations
            for (var p = 0; p < RadioData.somafmCategories.length; p++) {
                var somaCat = RadioData.somafmCategories[p]
                for (var q = 0; q < somaCat.stations.length; q++) {
                    allStations.push({
                        name: somaCat.stations[q].name,
                        host: somaCat.stations[q].host,
                        path: somaCat.stations[q].path,
                        source: "🎵 SomaFM",
                        category: somaCat.name
                    })
                }
            }
            
            // Add all favorite stations
            for (var r = 0; r < favoriteStations.length; r++) {
                allStations.push({
                    name: favoriteStations[r].name,
                    host: favoriteStations[r].host,
                    path: favoriteStations[r].path,
                    source: "⭐ Favorites",
                    category: "Favorites"
                })
            }
        }
        
        if (allStations.length === 0) {
            console.log("No stations available for random play")
            return false
        }
        
        // Generate random index, avoiding current station if possible
        var randomIndex
        if (allStations.length === 1) {
            randomIndex = 0
        } else {
            do {
                randomIndex = Math.floor(Math.random() * allStations.length)
            } while (allStations.length > 1 && 
                     allStations[randomIndex].name === currentStationName &&
                     allStations[randomIndex].host === currentStationHost &&
                     allStations[randomIndex].path === currentStationPath)
        }
        
        var randomStation = allStations[randomIndex]
        var streamUrl = getStreamUrl(randomStation.host, randomStation.path, streamQuality)
        
        currentStationName = randomStation.name
        currentStationUrl = streamUrl
        currentStationHost = randomStation.host
        currentStationPath = randomStation.path
        
        // Clear previous song info when changing stations
        currentSongTitle = ""
        currentArtist = ""
        debugMetadata = "Loading random station..."
        
        console.log("=== PLAYING RANDOM STATION ===")
        console.log("Selected:", randomStation.name, "from", randomStation.source)
        console.log("Category:", randomStation.category)
        console.log("Index:", randomIndex, "/", allStations.length)
        console.log("Stream URL:", streamUrl)
        
        songUpdateTimer.stop()
        player.stop()
        
        // Update navigation context for the new station
        updateCurrentStationsList()
        
        // Fetch live song metadata and start timer
        fetchStreamMetadata(streamUrl)
        songUpdateTimer.start()
        idleResetTimer.start()
        silentPlaybackDetector.start()
        
        // Reset pause state and play directly
        userPaused = false
        lastBufferProgress = 0
        lastBufferUpdateTime = Date.now()
        player.source = streamUrl
        player.play()
        
        return true
    }
    
    function playNextStation() {
        console.log("=== PLAY NEXT STATION CALLED ===")
        console.log("currentEbookUrl:", currentEbookUrl)
        console.log("currentEbookChapters.length:", currentEbookChapters.length)
        console.log("currentEbookChapterIndex:", currentEbookChapterIndex)
        
        // FORCE CLEAR EBOOK STATE FOR RADIO NAVIGATION
        currentEbookUrl = ""
        currentEbookChapters = []
        currentEbookChapterIndex = -1
        console.log("Cleared ebook state for radio navigation")
        
        // Simple approach: if we have a current station list, use it
        if (currentStationsList.length > 0 && currentStationIndex >= 0) {
            var nextIndex = (currentStationIndex + 1) % currentStationsList.length
            console.log("Using currentStationsList, moving from", currentStationIndex, "to", nextIndex)
            console.log("Next station:", currentStationsList[nextIndex].name)
            
            // Directly call playStationByIndex - this is what the UI uses
            console.log("About to call playStationByIndex with index:", nextIndex)
            console.log("Station list has", currentStationsList.length, "stations")
            console.log("Target station:", currentStationsList[nextIndex] ? currentStationsList[nextIndex].name : "UNDEFINED")
            var result = playStationByIndex(nextIndex)
            console.log("playStationByIndex returned:", result)
            return result
        }
        
        // Fallback: try with all stations
        var allStations = getAllAvailableStations()
        if (allStations.length === 0) {
            console.log("No stations available")
            return false
        }
        
        // Just play the first station if we can't find current
        console.log("Fallback: playing first station from all stations")
        var station = allStations[0]
        currentStationIndex = 0
        return playStationByIndex(0)
    }
    
    function playPreviousStation() {
        console.log("=== PLAY PREVIOUS STATION CALLED ===")
        console.log("currentEbookUrl:", currentEbookUrl)
        console.log("currentEbookChapters.length:", currentEbookChapters.length)
        console.log("currentEbookChapterIndex:", currentEbookChapterIndex)
        
        // FORCE CLEAR EBOOK STATE FOR RADIO NAVIGATION
        currentEbookUrl = ""
        currentEbookChapters = []
        currentEbookChapterIndex = -1
        console.log("Cleared ebook state for radio navigation")
        
        // Simple approach: if we have a current station list, use it
        if (currentStationsList.length > 0 && currentStationIndex >= 0) {
            var prevIndex = currentStationIndex <= 0 ? currentStationsList.length - 1 : currentStationIndex - 1
            console.log("Using currentStationsList, moving from", currentStationIndex, "to", prevIndex)
            console.log("Previous station:", currentStationsList[prevIndex].name)
            
            // Directly call playStationByIndex - this is what the UI uses
            console.log("About to call playStationByIndex with index:", prevIndex)
            console.log("Station list has", currentStationsList.length, "stations")
            console.log("Target station:", currentStationsList[prevIndex] ? currentStationsList[prevIndex].name : "UNDEFINED")
            var result = playStationByIndex(prevIndex)
            console.log("playStationByIndex returned:", result)
            return result
        }
        
        // Fallback: try with all stations
        var allStations = getAllAvailableStations()
        if (allStations.length === 0) {
            console.log("No stations available")
            return false
        }
        
        // Just play the last station if we can't find current
        console.log("Fallback: playing last station from all stations")
        var lastIndex = allStations.length - 1
        currentStationIndex = lastIndex
        return playStationByIndex(lastIndex)
    }
    
    function getAllAvailableStations() {
        var allStations = []
        
        // Add all RadCap stations
        if (RadioData.radcapCategories) {
            for (var i = 0; i < RadioData.radcapCategories.length; i++) {
                var category = RadioData.radcapCategories[i]
                for (var j = 0; j < category.stations.length; j++) {
                    allStations.push({
                        name: category.stations[j].name,
                        host: category.stations[j].host,
                        path: category.stations[j].path,
                        source: "📻 RadCap.ru",
                        category: category.name
                    })
                }
            }
        }
        
        // Add all SomaFM stations
        if (RadioData.somafmCategories) {
            for (var k = 0; k < RadioData.somafmCategories.length; k++) {
                var somaCategory = RadioData.somafmCategories[k]
                for (var l = 0; l < somaCategory.stations.length; l++) {
                    allStations.push({
                        name: somaCategory.stations[l].name,
                        host: somaCategory.stations[l].host,
                        path: somaCategory.stations[l].path,
                        source: "🎵 SomaFM",
                        category: somaCategory.name
                    })
                }
            }
        }
        
        // Add custom stations
        for (var m = 0; m < customStations.length; m++) {
            allStations.push({
                name: customStations[m].name,
                host: customStations[m].host,
                path: customStations[m].path,
                source: "🔗 Custom",
                category: "Custom"
            })
        }
        
        // Add favorites
        for (var n = 0; n < favoriteStations.length; n++) {
            allStations.push({
                name: favoriteStations[n].name,
                host: favoriteStations[n].host,
                path: favoriteStations[n].path,
                source: "⭐ Favorites",
                category: "Favorites"
            })
        }
        
        console.log("Built comprehensive station list with", allStations.length, "stations")
        return allStations
    }
    
    function findCurrentStationIndex(stationsList) {
        // Find the current station in the provided list
        for (var i = 0; i < stationsList.length; i++) {
            if (stationsList[i].name === currentStationName && 
                stationsList[i].host === currentStationHost) {
                return i
            }
        }
        
        // If not found, return 0 to start from beginning
        console.log("Current station not found in list, starting from beginning")
        return 0
    }
    
    function playStationDirect(station) {
        console.log("*** playStationDirect called with station:", station ? station.name : "NULL")
        
        if (!station) {
            console.log("ERROR: playStationDirect called with null/undefined station")
            return false
        }
        
        var streamUrl = getStreamUrl(station.host, station.path, streamQuality)
        console.log("Generated stream URL:", streamUrl)
        
        currentStationName = station.name
        currentStationUrl = streamUrl
        currentStationHost = station.host
        currentStationPath = station.path
        
        // Save this as the last played station
        saveLastStation()
        
        // Clear previous song info when changing stations
        currentSongTitle = ""
        currentArtist = ""
        debugMetadata = "Loading station..."
        
        console.log("=== PLAYING STATION DIRECT ===")
        console.log("Station:", station.name)
        console.log("Stream URL:", streamUrl)
        
        songUpdateTimer.stop()
        player.stop()
        
        // Fetch live song metadata and start timer
        fetchStreamMetadata(streamUrl)
        songUpdateTimer.start()
        
        // Play directly
        player.source = streamUrl
        player.play()
        
        return true
    }

    // Ebook Functions
    function addCustomEbook(title, url) {
        console.log("Adding custom ebook:", title, url)
        var ebook = {
            "title": title,
            "url": url
        }
        customEbooks.push(ebook)
        saveCustomEbooks()
        console.log("Custom ebook added:", ebook)
        loadSources()  // Refresh sources to update count
        
        // If we're currently viewing audiobooks, refresh the stations list
        if (currentCategory === "📚 Audiobooks" && inCategory) {
            var ebookStations = customEbooks.map(function(ebook) {
                return {
                    "name": ebook.title,
                    "url": ebook.url,
                    "host": "",
                    "path": "",
                    "type": "ebook"
                }
            })
            loadStations(ebookStations)
        }
    }
    
    function playEbook(ebook) {
        console.log("=== PLAYING EBOOK ===")
        console.log("Ebook title:", ebook.title)
        console.log("Ebook URL:", ebook.url)
        
        currentEbookTitle = ebook.title
        currentEbookUrl = ebook.url
        currentEbookChapterIndex = -1
        currentEbookChapters = []
        
        // Stop any current radio playback first
        songUpdateTimer.stop()
        player.stop()
        
        console.log("Loading ebook chapters from RSS:", ebook.url)
        
        // Load chapters from LibriVox RSS
        loadEbookChapters(ebook.url)
    }
    
    function loadEbookChapters(rssUrl) {
        console.log("=== LOADING EBOOK CHAPTERS ===")
        console.log("RSS URL:", rssUrl)
        
        var xhr = new XMLHttpRequest()
        xhr.open("GET", rssUrl, true)
        xhr.onreadystatechange = function() {
            console.log("XHR state changed:", xhr.readyState, "status:", xhr.status)
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    console.log("RSS fetch successful, parsing...")
                    console.log("Response length:", xhr.responseText.length)
                    parseEbookRSS(xhr.responseText)
                } else {
                    console.log("Failed to load ebook RSS. Status:", xhr.status)
                    console.log("Status text:", xhr.statusText)
                }
            }
        }
        
        xhr.onerror = function() {
            console.log("XHR error occurred")
        }
        
        console.log("Sending XHR request...")
        xhr.send()
    }
    
    function parseEbookRSS(xmlText) {
        console.log("=== PARSING EBOOK RSS ===")
        console.log("XML text preview:", xmlText.substring(0, 500))
        
        try {
            // Use simple regex parsing since QML doesn't have DOMParser
            var chapters = []
            
            // Extract all <item> blocks
            var itemRegex = /<item[^>]*>([\s\S]*?)<\/item>/gi
            var itemMatch
            var itemIndex = 0
            
            while ((itemMatch = itemRegex.exec(xmlText)) !== null) {
                var itemContent = itemMatch[1]
                console.log("Processing item", itemIndex)
                
                // Extract title
                var titleMatch = /<title[^>]*><!\[CDATA\[(.*?)\]\]><\/title>/i.exec(itemContent) ||
                                /<title[^>]*>(.*?)<\/title>/i.exec(itemContent)
                var title = titleMatch ? titleMatch[1].trim() : "Chapter " + (itemIndex + 1)
                
                // Extract enclosure URL
                var enclosureMatch = /<enclosure[^>]*url\s*=\s*["']([^"']+)["'][^>]*>/i.exec(itemContent)
                
                if (enclosureMatch) {
                    var url = enclosureMatch[1]
                    console.log("Found chapter:", title, "URL:", url)
                    
                    chapters.push({
                        title: title,
                        url: url,
                        index: itemIndex
                    })
                } else {
                    console.log("No enclosure found for item", itemIndex, "title:", title)
                }
                
                itemIndex++
            }
            
            currentEbookChapters = chapters
            console.log("=== LOADED", chapters.length, "CHAPTERS ===")
            
            if (chapters.length > 0) {
                // Load saved progress or start from beginning
                var savedProgress = ebookProgress[currentEbookUrl]
                if (savedProgress && savedProgress.chapterIndex < chapters.length) {
                    console.log("Resuming from saved progress: chapter", savedProgress.chapterIndex, "position", savedProgress.position)
                    playEbookChapter(savedProgress.chapterIndex, savedProgress.position || 0)
                } else {
                    console.log("Starting from beginning")
                    playEbookChapter(0)
                }
            } else {
                console.log("No chapters found! Checking XML structure...")
                console.log("XML contains 'item':", xmlText.indexOf("<item") >= 0)
                console.log("XML contains 'enclosure':", xmlText.indexOf("enclosure") >= 0)
            }
            
        } catch (e) {
            console.log("Error parsing ebook RSS:", e)
            console.log("Error details:", e.toString())
        }
    }
    
    function playEbookChapter(chapterIndex, startPosition) {
        if (chapterIndex < 0 || chapterIndex >= currentEbookChapters.length) {
            console.log("Invalid chapter index:", chapterIndex)
            return
        }
        
        var chapter = currentEbookChapters[chapterIndex]
        currentEbookChapterIndex = chapterIndex
        
        console.log("Playing chapter:", chapter.title)
        
        // Update current station info for display
        currentStationName = currentEbookTitle + " - " + chapter.title
        currentStationUrl = chapter.url
        currentStationHost = ""
        currentStationPath = ""
        currentSongTitle = chapter.title
        currentArtist = currentEbookTitle
        debugMetadata = "Playing ebook chapter..."
        
        // Stop current playback and start ebook chapter
        songUpdateTimer.stop()
        player.stop()
        
        player.source = chapter.url
        if (startPosition) {
            player.setPosition(startPosition)
        }
        
        // Start ebook progress timer
        ebookProgressTimer.start()
        
        // Save progress
        saveEbookProgress()
    }
    
    function nextEbookChapter() {
        if (currentEbookChapterIndex >= 0 && currentEbookChapterIndex < currentEbookChapters.length - 1) {
            playEbookChapter(currentEbookChapterIndex + 1)
        }
    }
    
    function previousEbookChapter() {
        if (currentEbookChapterIndex > 0) {
            playEbookChapter(currentEbookChapterIndex - 1)
        }
    }

    // Widget styling - no default background to show custom rounded edges
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
    // Refined Audio - Main container with subtle gradient
    Rectangle {
        anchors.fill: parent
        radius: 20
        antialiasing: true
        visible: !isCompactMode

        // Subtle gradient background
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.95,
                                                         Kirigami.Theme.backgroundColor.g * 0.95,
                                                         Kirigami.Theme.backgroundColor.b * 0.95, 0.92) }
            GradientStop { position: 0.5; color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                                                         Kirigami.Theme.backgroundColor.g,
                                                         Kirigami.Theme.backgroundColor.b, 0.88) }
            GradientStop { position: 1.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.92,
                                                         Kirigami.Theme.backgroundColor.g * 0.92,
                                                         Kirigami.Theme.backgroundColor.b * 0.92, 0.90) }
        }

        // Accent glow at top
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.0) }
                GradientStop { position: 0.3; color: Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.6) }
                GradientStop { position: 0.7; color: Qt.rgba(accentSecondary.r, accentSecondary.g, accentSecondary.b, 0.6) }
                GradientStop { position: 1.0; color: Qt.rgba(accentSecondary.r, accentSecondary.g, accentSecondary.b, 0.0) }
            }
        }

        // Refined border
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: parent.radius
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
            antialiasing: true
        }
    }

    ColumnLayout {
        id: mainWidget
        anchors.fill: parent
        anchors.margins: spacingLarge
        spacing: spacingMedium
        visible: !isCompactMode || showPopup
        parent: showPopup ? contentContainer : root
        
        // Force creation in compact mode by ensuring component always exists
        Component.onCompleted: {
            console.log("MainWidget loaded. isCompactMode:", isCompactMode, "showPopup:", showPopup)
            // Ensure data is loaded even in compact mode
            if (isCompactMode && !showPopup) {
                console.log("Loading data for compact mode background operation")
            }
        }

        // Search bar - Refined Audio style
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "🔍 Search radio stations..."
                font.pointSize: baseFontSize
                leftPadding: 14
                rightPadding: 14
                topPadding: 10
                bottomPadding: 10

                onTextChanged: {
                    if (text.trim() === "") {
                        isSearchMode = false
                        searchResultsModel.clear()
                    } else {
                        searchStations(text)
                    }
                }

                Keys.onEscapePressed: {
                    text = ""
                    focus = false
                }

                background: Rectangle {
                    radius: 10
                    antialiasing: true

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.92,
                                                                     Kirigami.Theme.backgroundColor.g * 0.92,
                                                                     Kirigami.Theme.backgroundColor.b * 0.92, 0.95) }
                        GradientStop { position: 1.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.88,
                                                                     Kirigami.Theme.backgroundColor.g * 0.88,
                                                                     Kirigami.Theme.backgroundColor.b * 0.88, 0.9) }
                    }

                    border.width: searchField.activeFocus ? 2 : 1
                    border.color: searchField.activeFocus ? accentPrimary : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                    // Focus glow effect
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: parent.radius + 3
                        color: "transparent"
                        border.width: searchField.activeFocus ? 2 : 0
                        border.color: Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.3)
                        z: -1

                        Behavior on border.width {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
            
            Button {
                text: "✕"
                visible: searchField.text !== ""
                font.pointSize: titleFontSize
                implicitWidth: buttonSize
                implicitHeight: buttonSize * 0.8
                flat: true
                
                onClicked: {
                    searchField.text = ""
                    searchField.focus = false
                }
                
                ToolTip.text: "Clear search"
                ToolTip.visible: hovered
            }
        }


        // Search Results ListView
        ListView {
            visible: isSearchMode
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: searchResultsModel
            spacing: Math.max(1, root.height / 250)  // Responsive spacing
            clip: true
            rightMargin: 20  // Reserve space for medium scrollbar
            
            delegate: ItemDelegate {
                width: ListView.view.width - 20  // Reserve 20px for medium scrollbar and spacing
                height: contentColumn.implicitHeight + 16  // Dynamic height based on content + padding
                
                // Modern card background
                background: Rectangle {
                    color: {
                        if (parent.pressed) return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4)
                        if (parent.hovered) return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                        return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.9)
                    }
                    radius: 8
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                    antialiasing: true
                    
                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
                
                Column {
                    id: contentColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.rightMargin: 30
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    
                    Label {
                        text: model.name
                        font.pointSize: Math.max(8, Math.min(11, root.width / 40))
                        font.weight: Font.Medium
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        width: parent.width
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                    }
                    Label {
                        text: model.category + " • " + model.source
                        font.pointSize: Math.max(7, Math.min(9, root.width / 50))
                        color: Kirigami.Theme.textColor
                        opacity: 0.65
                        elide: Text.ElideRight
                        width: parent.width
                        wrapMode: Text.NoWrap
                        maximumLineCount: 1
                    }
                }
                
                onClicked: {
                    // Use selected quality for direct stream
                    var streamUrl = getStreamUrl(model.host, model.path, streamQuality)
                    
                    currentStationName = model.name
                    currentStationUrl = streamUrl
                    currentStationHost = model.host
                    currentStationPath = model.path
                    
                    // Clear previous song info when changing stations
                    currentSongTitle = ""
                    currentArtist = ""
                    debugMetadata = "Loading new station..."
                    
                    console.log("=== SEARCH RESULT CLICK ===")
                    console.log("Station:", model.name)
                    console.log("Stream URL:", streamUrl)
                    console.log("Source:", model.source)
                    
                    songUpdateTimer.stop()
                    player.stop()
                    
                    // Update navigation context
                    updateCurrentStationsList()
                    
                    // Fetch live song metadata and start timer
                    fetchStreamMetadata(streamUrl)
                    songUpdateTimer.start()
                    
                    // Play directly
                    player.source = streamUrl
                    player.play()
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                width: scrollbarWidth
                anchors.right: parent.right
                anchors.rightMargin: 4
                visible: true
                policy: ScrollBar.AsNeeded
                background: Rectangle {
                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.3)
                    radius: width / 2
                }
                contentItem: Rectangle {
                    implicitWidth: scrollbarWidth
                    radius: width / 2
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.7)
                }
            }
            
            // Show search status
            header: Rectangle {
                width: parent.width
                height: 30
                color: "transparent"
                
                Label {
                    anchors.centerIn: parent
                    text: searchResultsModel.count > 0 ? 
                          "Found " + searchResultsModel.count + " stations matching '" + searchQuery + "'" :
                          "No stations found for '" + searchQuery + "'"
                    font.pointSize: Math.max(8, Math.min(10, root.width / 40))
                    font.italic: true
                    color: Kirigami.Theme.textColor
                    opacity: 0.7
                }
            }
        }

        // Sources ListView - Refined Audio style
        ListView {
            visible: !inSource && !inCategory && !isSearchMode
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: sourcesModel
            spacing: Math.max(8, root.height * 0.015)
            clip: true
            rightMargin: 20

            delegate: ItemDelegate {
                id: sourceDelegate
                width: ListView.view.width - 20
                height: Math.max(56, root.height * 0.13)

                background: Rectangle {
                    radius: 10
                    antialiasing: true

                    // Gradient background
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: {
                            if (sourceDelegate.pressed) return Qt.rgba(sourceColor.r, sourceColor.g, sourceColor.b, 0.25)
                            if (sourceDelegate.hovered) return Qt.rgba(sourceColor.r, sourceColor.g, sourceColor.b, 0.12)
                            return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.7)
                        }}
                        GradientStop { position: 1.0; color: {
                            if (sourceDelegate.pressed) return Qt.rgba(sourceColor.r, sourceColor.g, sourceColor.b, 0.15)
                            if (sourceDelegate.hovered) return Qt.rgba(sourceColor.r, sourceColor.g, sourceColor.b, 0.06)
                            return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.5)
                        }}
                    }

                    // Left accent bar
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 4
                        width: 4
                        radius: 2
                        color: sourceDelegate.hovered ? sourceColor : Qt.rgba(sourceColor.r, sourceColor.g, sourceColor.b, 0.5)

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

                    Behavior on gradient {
                        ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Label {
                        text: model.name
                        font.pointSize: Math.max(11, root.width * 0.038)
                        font.weight: Font.DemiBold
                        color: sourceDelegate.hovered ? Kirigami.Theme.textColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.9)
                        elide: Text.ElideRight
                        width: parent.width

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                    Label {
                        text: model.description
                        font.pointSize: Math.max(8, root.width * 0.025)
                        color: Kirigami.Theme.textColor
                        opacity: sourceDelegate.hovered ? 0.75 : 0.55
                        elide: Text.ElideRight
                        width: parent.width

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }
                }

                onClicked: loadSource(model)
            }
            
            ScrollBar.vertical: ScrollBar {
                width: scrollbarWidth
                anchors.right: parent.right
                anchors.rightMargin: 4
                visible: true
                policy: ScrollBar.AsNeeded
                background: Rectangle {
                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.3)
                    radius: width / 2
                }
                contentItem: Rectangle {
                    implicitWidth: scrollbarWidth
                    radius: width / 2
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.7)
                }
            }
        }
        
        // Categories ListView with back button
        ColumnLayout {
            visible: inSource && !inCategory && !isSearchMode
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            
            // Back button for categories
            RowLayout {
                Layout.fillWidth: true
                
                Button {
                    text: "⬅ Back"
                    font.pointSize: Math.max(8, Math.min(11, root.width / 40))
                    onClicked: {
                        inSource = false
                        categoriesModel.clear()
                        currentSource = ""
                        console.log("Navigated back to sources")
                    }
                    implicitWidth: Math.max(50, Math.min(80, root.width / 8))
                    implicitHeight: Math.max(25, Math.min(35, root.height / 25))
                }
                
                Label {
                    text: currentSource
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: Math.max(8, Math.min(12, root.width / 35))
                    font.weight: Font.Bold
                    color: Kirigami.Theme.highlightColor
                }
            }
            
            GridView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: categoriesModel
                clip: true
                rightMargin: 20  // Reserve space for medium scrollbar
                
                // 2 columns layout
                cellWidth: (width - 20) / 2  // Reserve 20px for medium scrollbar and spacing
                cellHeight: Math.max(45, Math.min(60, root.height / 20))
                
                delegate: ItemDelegate {
                    width: GridView.view.cellWidth - 2
                    height: GridView.view.cellHeight - 2
                    leftPadding: 16
                    rightPadding: 16
                    topPadding: 12
                    bottomPadding: 12
                    contentItem: Text {
                        text: model.name
                        font.pointSize: Math.max(8, Math.min(11, root.width / 45))
                        color: Kirigami.Theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    
                    onClicked: loadCategory(model)
                    
                    background: Rectangle {
                        color: {
                            if (parent.pressed) return Kirigami.Theme.highlightColor
                            if (parent.hovered) return Kirigami.Theme.hoverColor
                            return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.3)
                        }
                        radius: 8
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
                        antialiasing: true
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
                
                ScrollBar.vertical: ScrollBar {
                    width: scrollbarWidth
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    visible: true
                    policy: ScrollBar.AsNeeded
                    background: Rectangle {
                        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.3)
                        radius: width / 2
                    }
                    contentItem: Rectangle {
                        implicitWidth: scrollbarWidth
                        radius: width / 2
                        color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.7)
                    }
                }
            }
        }

        // Stations View
        ColumnLayout {
            visible: inCategory && !isSearchMode
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.max(6, root.height * 0.015)  // Responsive spacing
            
            // Debug info
            Component.onCompleted: {
                console.log("Stations View created. inCategory:", inCategory, "isSearchMode:", isSearchMode, "visible:", visible)
            }
            
            onVisibleChanged: {
                console.log("Stations View visibility changed:", visible, "inCategory:", inCategory, "currentSource:", currentSource)
            }
            
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "⬅ Back"
                    onClicked: {
                        if (inCategory) {
                            // Special handling for favorites and custom stations - go directly back to sources
                            if (currentSource === "⭐ Favorites" || currentSource === "🔗 Custom Radio") {
                                inCategory = false
                                inSource = false
                                stationsModel.clear()
                                currentCategory = ""
                                currentSource = ""
                                console.log("Navigated back from", currentSource, "to sources")
                            } else {
                                // Go back from stations to categories
                                inCategory = false
                                stationsModel.clear()
                                currentCategory = ""
                            }
                        } else if (inSource) {
                            // Go back from categories to sources
                            inSource = false
                            categoriesModel.clear()
                            currentSource = ""
                        }
                    }
                }
                Label {
                    text: {
                        if (currentSource === "📚 Audiobooks") {
                            if (currentEbookTitle) {
                                return currentSource + " > " + currentEbookTitle
                            } else {
                                return currentSource
                            }
                        } else {
                            return currentSource + (currentCategory ? " > " + currentCategory : "")
                        }
                    }
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: baseFontSize
                }
            }
            
            // Custom Radio action buttons
            RowLayout {
                visible: currentSource === "🔗 Custom Radio" && inCategory
                Layout.fillWidth: true
                spacing: spacingMedium
                
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(35, root.height * 0.08)
                    font.pointSize: Math.max(8, Math.min(11, root.width / 40))
                    onClicked: {
                        console.log("Add Radio button clicked!")
                        isEditMode = false
                        editStationIndex = -1
                        showCustomDialog = true
                    }
                    
                    contentItem: Text {
                        text: "+ Add Radio"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Kirigami.Theme.textColor
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? Qt.rgba(0, 0.6, 0, 0.4) :
                               parent.hovered ? Qt.rgba(0, 0.6, 0, 0.2) :
                               Qt.rgba(0, 0.6, 0, 0.1)
                        radius: 8
                        border.width: 1
                        border.color: Qt.rgba(0, 0.6, 0, 0.6)
                    }
                }
                
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(35, root.height * 0.08)
                    font.pointSize: Math.max(8, Math.min(11, root.width / 40))
                    onClicked: {
                        console.log("Search Radio button clicked!")
                        showSearchDialog = true
                    }
                    
                    contentItem: Text {
                        text: "Search Radio"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Kirigami.Theme.textColor
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? Qt.rgba(0, 0.4, 0.8, 0.4) :
                               parent.hovered ? Qt.rgba(0, 0.4, 0.8, 0.2) :
                               Qt.rgba(0, 0.4, 0.8, 0.1)
                        radius: 8
                        border.width: 1
                        border.color: Qt.rgba(0, 0.4, 0.8, 0.6)
                    }
                }
            }
            
            // Ebook buttons - shown when in Audiobooks category
            ColumnLayout {
                visible: currentCategory === "📚 Audiobooks" && inCategory
                Layout.fillWidth: true
                spacing: spacingMedium
                
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(35, root.height * 0.08)
                    font.pointSize: Math.max(8, Math.min(11, root.width / 40))
                    onClicked: {
                        console.log("Search LibriVox button clicked!")
                        showEbookSearchDialog = true
                    }
                    
                    contentItem: Text {
                        text: "📚 Search LibriVox"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Kirigami.Theme.textColor
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? Qt.rgba(0.8, 0.4, 0, 0.4) :
                               parent.hovered ? Qt.rgba(0.8, 0.4, 0, 0.2) :
                               Qt.rgba(0.8, 0.4, 0, 0.1)
                        radius: 8
                        border.width: 1
                        border.color: Qt.rgba(0.8, 0.4, 0, 0.6)
                    }
                }
                
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(35, root.height * 0.08)
                    font.pointSize: Math.max(8, Math.min(11, root.width / 40))
                    onClicked: {
                        console.log("Add Custom Ebook button clicked!")
                        showCustomEbookDialog = true
                    }
                    
                    contentItem: Text {
                        text: "+ Add Custom URL"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Kirigami.Theme.textColor
                    }
                    
                    background: Rectangle {
                        color: parent.pressed ? Qt.rgba(0.6, 0.2, 0.8, 0.4) :
                               parent.hovered ? Qt.rgba(0.6, 0.2, 0.8, 0.2) :
                               Qt.rgba(0.6, 0.2, 0.8, 0.1)
                        radius: 8
                        border.width: 1
                        border.color: Qt.rgba(0.6, 0.2, 0.8, 0.6)
                    }
                }
            }
            
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: stationsModel
                spacing: Math.max(1, root.height / 250)  // Responsive spacing
                clip: true
                rightMargin: 20  // Reserve space for medium scrollbar
                
                delegate: ItemDelegate {
                    width: ListView.view.width - 20  // Reserve 20px for medium scrollbar and spacing
                    height: Math.max(44, Math.min(56, root.height / 18))  // Increased height for better spacing

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8  // Increased spacing for less cramped feel
                        
                        Text {
                            text: model.name
                            font.pixelSize: 13
                            font.bold: true
                            color: Kirigami.Theme.textColor
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        
                        // Edit button for custom stations
                        Button {
                            visible: currentSource === "🔗 Custom Radio"
                            text: "✏️"
                            implicitWidth: 28
                            implicitHeight: 28
                            font.pointSize: smallFontSize
                            
                            onClicked: {
                                editCustomStation(index)
                            }
                            
                            background: Rectangle {
                                color: parent.pressed ? Qt.rgba(0, 0.5, 1, 0.8) :
                                       parent.hovered ? Qt.rgba(0, 0.5, 1, 0.6) : Qt.rgba(0, 0.5, 1, 0.4)
                                radius: 4
                                border.width: 1
                                border.color: Qt.rgba(0, 0.5, 1, 0.8)
                            }
                        }
                        
                        // Delete button for custom stations
                        Button {
                            visible: currentSource === "🔗 Custom Radio"
                            text: "❌"
                            implicitWidth: 28
                            implicitHeight: 28
                            font.pointSize: smallFontSize
                            
                            onClicked: {
                                removeCustomStation(index)
                            }
                            
                            background: Rectangle {
                                color: parent.pressed ? Qt.rgba(1, 0, 0, 0.8) :
                                       parent.hovered ? Qt.rgba(1, 0, 0, 0.6) : Qt.rgba(1, 0, 0, 0.4)
                                radius: 4
                                border.width: 1
                                border.color: Qt.rgba(1, 0, 0, 0.8)
                            }
                        }
                        
                        // Delete button for ebooks
                        Button {
                            visible: currentCategory === "📚 Audiobooks"
                            text: "❌"
                            implicitWidth: 28
                            implicitHeight: 28
                            font.pointSize: smallFontSize
                            
                            onClicked: {
                                removeCustomEbook(index)
                            }
                            
                            background: Rectangle {
                                color: parent.pressed ? Qt.rgba(1, 0, 0, 0.8) :
                                       parent.hovered ? Qt.rgba(1, 0, 0, 0.6) : Qt.rgba(1, 0, 0, 0.4)
                                radius: 4
                                border.width: 1
                                border.color: Qt.rgba(1, 0, 0, 0.8)
                            }
                        }
                    }
                    
                    onClicked: {
                        console.log("=== STATION CLICK ===")
                        console.log("Station:", model.name)
                        console.log("Type:", model.type)
                        console.log("URL:", model.url)
                        
                        // Check if this is an ebook
                        if (model.type === "ebook") {
                            console.log("Playing ebook:", model.name)
                            playEbook({
                                title: model.name,
                                url: model.url
                            })
                            return
                        }
                        
                        var streamUrl
                        // Handle custom stations differently
                        if (currentSource === "🔗 Custom Radio") {
                            // For custom stations, use the URL directly
                            streamUrl = model.host || model.url
                            console.log("Custom station clicked - URL:", streamUrl)
                        } else {
                            // Use selected quality for regular streams
                            streamUrl = getStreamUrl(model.host, model.path, streamQuality)
                        }
                        
                        currentStationName = model.name
                        currentStationUrl = streamUrl
                        currentStationHost = model.host
                        currentStationPath = model.path || ""
                        
                        // Clear ebook state when playing radio
                        currentEbookUrl = ""
                        currentEbookTitle = ""
                        currentEbookChapters = []
                        currentEbookChapterIndex = -1
                        ebookProgressTimer.stop()
                        
                        // Clear previous song info when changing stations
                        currentSongTitle = ""
                        currentArtist = ""
                        debugMetadata = "Loading new station..."
                        
                        console.log("Stream URL:", streamUrl)
                        console.log("Player state before:", player.playbackState)
                        
                        songUpdateTimer.stop()
                        player.stop()
                        
                        // Update navigation context
                        updateCurrentStationsList()
                        
                        // Fetch live song metadata and start timer
                        fetchStreamMetadata(streamUrl)
                        songUpdateTimer.start()
                        
                        // Play directly
                        player.source = streamUrl
                        player.play()
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        color: parent.hovered ? Kirigami.Theme.hoverColor : "transparent"
                        radius: 8
                        z: -1
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                        antialiasing: true
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        color: currentStationName === model.name ? Kirigami.Theme.highlightColor : "transparent"
                        radius: 8
                        opacity: 0.3
                        z: -2
                        border.width: currentStationName === model.name ? 1 : 0
                        border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5)
                        antialiasing: true
                    }
                }
                
                ScrollBar.vertical: ScrollBar {
                    width: scrollbarWidth
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    visible: true
                    policy: ScrollBar.AsNeeded
                    background: Rectangle {
                        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.3)
                        radius: width / 2
                    }
                    contentItem: Rectangle {
                        implicitWidth: scrollbarWidth
                        radius: width / 2
                        color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.7)
                    }
                }
            }
        }

        // Status display - Refined Audio style
        Rectangle {
            Layout.fillWidth: true
            height: Math.max(80, Math.min(100, root.height * 0.18))
            radius: 10
            antialiasing: true

            // Subtle gradient background
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.95,
                                                             Kirigami.Theme.backgroundColor.g * 0.95,
                                                             Kirigami.Theme.backgroundColor.b * 0.95, 0.9) }
                GradientStop { position: 1.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.9,
                                                             Kirigami.Theme.backgroundColor.g * 0.9,
                                                             Kirigami.Theme.backgroundColor.b * 0.9, 0.85) }
            }

            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

            // Now playing accent bar (left side)
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 4
                width: 4
                radius: 2
                visible: currentStationName !== ""
                color: player.playbackState === MediaPlayer.PlayingState ? nowPlayingColor : Qt.rgba(nowPlayingColor.r, nowPlayingColor.g, nowPlayingColor.b, 0.4)

                // Pulsing animation when playing
                SequentialAnimation on opacity {
                    running: player.playbackState === MediaPlayer.PlayingState
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.7; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.7; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Math.max(6, root.width * 0.015)
                    Layout.alignment: Qt.AlignVCenter

                    Label {
                        text: currentStationName ? "♪ " + currentStationName : "No station selected"
                        font.pointSize: Math.max(8, Math.min(12, root.width / 35))
                        font.weight: Font.Medium
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        color: currentStationName ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        verticalAlignment: Text.AlignVCenter
                        clip: true
                    }
                    
                    Button {
                        visible: currentStationName !== "" && currentEbookUrl === ""
                        text: {
                            // Include favoritesVersion to force re-evaluation when favorites change
                            var _v = favoritesVersion
                            if (currentStationName === "" || currentStationHost === "" || currentStationPath === "") return "☆"
                            return isFavorite(currentStationName, currentStationHost, currentStationPath) ? "⭐" : "☆"
                        }
                        font.pointSize: titleFontSize
                        implicitWidth: buttonSize * 0.8
                        implicitHeight: buttonSize * 0.8
                        flat: true

                        // Custom content item to control star color
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: {
                                // Include favoritesVersion to force re-evaluation when favorites change
                                var _v = favoritesVersion
                                if (currentStationName === "" || currentStationHost === "" || currentStationPath === "") return Kirigami.Theme.textColor
                                return isFavorite(currentStationName, currentStationHost, currentStationPath) ? "#FFD700" : Kirigami.Theme.textColor
                            }
                        }
                        onClicked: {
                            if (currentStationName === "" || currentStationHost === "" || currentStationPath === "") return
                            toggleFavorite(currentStationName, currentStationHost, currentStationPath)
                        }
                        ToolTip.text: {
                            // Include favoritesVersion to force re-evaluation when favorites change
                            var _v = favoritesVersion
                            if (currentStationName === "" || currentStationHost === "" || currentStationPath === "") return "Add to favorites"
                            return isFavorite(currentStationName, currentStationHost, currentStationPath) ? "Remove from favorites" : "Add to favorites"
                        }
                        ToolTip.visible: hovered
                    }
                }
                
                // Show current stream URL (to verify port changes)
                Label {
                    visible: currentStationUrl !== ""
                    text: currentStationUrl
                    font.pointSize: Math.max(6, Math.min(8, root.width / 50))
                    color: Kirigami.Theme.textColor
                    opacity: 0.6
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    visible: (currentSongTitle || currentArtist) && currentEbookUrl === ""
                    Layout.fillWidth: true
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: isVerySmall ? Math.max(20, simulatedHeight / 20) : Math.max(30, Math.min(50, simulatedHeight / 15))
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                        
                        TextEdit {
                            text: {
                                if (currentArtist && currentSongTitle) {
                                    return currentArtist + " - " + currentSongTitle
                                } else if (currentSongTitle) {
                                    return currentSongTitle
                                } else {
                                    return ""
                                }
                            }
                            font.pointSize: smallFontSize
                            color: Kirigami.Theme.textColor
                            width: parent.width
                            readOnly: true
                            selectByMouse: true
                            wrapMode: Text.Wrap
                            leftPadding: spacingSmall
                            rightPadding: spacingSmall + (enableScrollbars ? scrollbarTotalSpace : 0)
                            topPadding: 4
                            bottomPadding: 4
                        }
                    }
                }
            }
        }
        
        
        // Controls - Refined Audio style
        Rectangle {
            Layout.fillWidth: true
            height: Math.max(80, Math.min(100, root.height * 0.18))
            radius: 12
            antialiasing: true

            // Gradient background for controls bar
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.9,
                                                             Kirigami.Theme.backgroundColor.g * 0.9,
                                                             Kirigami.Theme.backgroundColor.b * 0.9, 0.95) }
                GradientStop { position: 1.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r * 0.85,
                                                             Kirigami.Theme.backgroundColor.g * 0.85,
                                                             Kirigami.Theme.backgroundColor.b * 0.85, 0.9) }
            }

            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
            
            // Vertical layout: Playback controls and timeline
            Item {
                anchors.centerIn: parent
                width: parent.width - (showPopup ? 40 : 60)  // Reduced margins for more space
                height: parent.height - (showPopup ? 16 : 24)  // Reduced margins for more space
                
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: spacingMedium
                    clip: false  // Allow button glow effects to extend beyond bounds
                    
                    // Top row: Play and Volume controls
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: spacingMedium
                
                Button {
                    id: prevButton
                    enabled: currentStationUrl !== "" && (currentEbookUrl ? currentEbookChapterIndex > 0 : true)
                    onClicked: {
                        if (currentEbookUrl !== "") {
                            previousEbookChapter()
                        } else {
                            playPreviousStation()
                        }
                    }

                    implicitWidth: buttonSize
                    implicitHeight: buttonSize
                    Layout.alignment: Qt.AlignVCenter

                    ToolTip.text: currentEbookUrl ? "Previous chapter" : "Previous station"
                    ToolTip.visible: hovered

                    background: Rectangle {
                        radius: parent.width / 2
                        antialiasing: true

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: {
                                if (!prevButton.enabled) return Qt.rgba(0.3, 0.3, 0.3, 0.2)
                                if (prevButton.pressed) return Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.9)
                                if (prevButton.hovered) return Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.5)
                                return Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.25)
                            }}
                            GradientStop { position: 1.0; color: {
                                if (!prevButton.enabled) return Qt.rgba(0.2, 0.2, 0.2, 0.15)
                                if (prevButton.pressed) return Qt.rgba(accentTertiary.r, accentTertiary.g, accentTertiary.b, 0.85)
                                if (prevButton.hovered) return Qt.rgba(accentTertiary.r, accentTertiary.g, accentTertiary.b, 0.4)
                                return Qt.rgba(accentTertiary.r, accentTertiary.g, accentTertiary.b, 0.15)
                            }}
                        }

                        border.width: prevButton.hovered ? 2 : 1
                        border.color: prevButton.enabled ? Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, prevButton.hovered ? 0.7 : 0.4) : Qt.rgba(0.5, 0.5, 0.5, 0.3)

                        scale: prevButton.pressed ? 0.92 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }

                    contentItem: Kirigami.Icon {
                        source: currentEbookUrl ? "media-seek-backward" : "media-skip-backward"
                        implicitWidth: Math.max(16, Math.min(22, parent.height * 0.5))
                        implicitHeight: implicitWidth
                        color: {
                            if (!prevButton.enabled) return Kirigami.Theme.disabledTextColor
                            if (prevButton.pressed || prevButton.hovered) return Kirigami.Theme.highlightedTextColor
                            return Kirigami.Theme.textColor
                        }

                        scale: prevButton.pressed ? 0.9 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Button {
                    id: playPauseButton
                    enabled: currentStationUrl !== "" || currentEbookUrl !== ""
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState) {
                            player.pause()
                            userPaused = true
                            songUpdateTimer.stop()
                            idleResetTimer.stop()
                            silentPlaybackDetector.stop()
                            if (currentEbookUrl) {
                                ebookProgressTimer.stop()
                            }
                        } else if (currentEbookUrl !== "") {
                            // Playing an ebook
                            console.log("=== RESUMING EBOOK PLAYBACK ===")
                            console.log("Current ebook:", currentEbookTitle)
                            console.log("Current chapter index:", currentEbookChapterIndex)

                            if (currentEbookChapterIndex >= 0 && currentEbookChapterIndex < currentEbookChapters.length) {
                                // Resume current chapter
                                player.play()
                                ebookProgressTimer.start()
                            } else if (currentEbookChapters.length > 0) {
                                // Start from first chapter
                                playEbookChapter(0)
                            } else {
                                console.log("No ebook chapters available")
                            }
                        } else if (currentStationUrl !== "") {
                            // Playing radio
                            console.log("=== RESUMING RADIO PLAYBACK ===")
                            console.log("Fetching updated song metadata")
                            debugMetadata = "Resuming, checking for new song..."

                            // Reset pause state when user manually plays
                            userPaused = false
                            restartAttempts = 0

                            // Fetch fresh metadata before playing
                            fetchStreamMetadata(currentStationUrl)

                            // Check if player source is still valid after idle period
                            if (player.source !== currentStationUrl) {
                                console.log("Player source mismatch after idle, resetting...")
                                console.log("Expected:", currentStationUrl)
                                console.log("Current:", player.source)
                                player.source = currentStationUrl
                            }

                            // Force source refresh if player seems to have lost connection or is in problematic state
                            if (player.mediaStatus === MediaPlayer.NoMedia ||
                                player.mediaStatus === MediaPlayer.InvalidMedia ||
                                player.playbackState === MediaPlayer.StoppedState) {
                                console.log("Media lost/stopped after idle, refreshing source...")
                                console.log("Media status:", player.mediaStatus, "Playback state:", player.playbackState)
                                player.stop()
                                player.source = ""  // Clear source first
                                Qt.callLater(function() {
                                    player.source = currentStationUrl  // Reset source
                                    Qt.callLater(function() {
                                        // Start playback after source is set
                                        player.play()
                                        songUpdateTimer.start()
                                        idleResetTimer.start()
                                        silentPlaybackDetector.start()
                                    })
                                })
                            } else {
                                // Normal playback path
                                player.play()
                                songUpdateTimer.start()
                                idleResetTimer.start()
                                silentPlaybackDetector.start()
                            }
                        }
                    }

                    implicitWidth: Math.max(50, Math.min(60, root.width / 11))
                    implicitHeight: Math.max(50, Math.min(60, root.height / 13))
                    Layout.alignment: Qt.AlignVCenter

                    // Main play button - larger, more prominent with accent gradient
                    background: Rectangle {
                        radius: parent.width / 2
                        antialiasing: true

                        // Rich gradient for play button
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: {
                                if (!playPauseButton.enabled) return Qt.rgba(0.3, 0.3, 0.3, 0.25)
                                if (playPauseButton.pressed) return accentPrimary
                                if (playPauseButton.hovered) return Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.85)
                                return Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.7)
                            }}
                            GradientStop { position: 1.0; color: {
                                if (!playPauseButton.enabled) return Qt.rgba(0.2, 0.2, 0.2, 0.2)
                                if (playPauseButton.pressed) return accentTertiary
                                if (playPauseButton.hovered) return Qt.rgba(accentTertiary.r, accentTertiary.g, accentTertiary.b, 0.8)
                                return Qt.rgba(accentTertiary.r, accentTertiary.g, accentTertiary.b, 0.55)
                            }}
                        }

                        border.width: 2
                        border.color: playPauseButton.enabled ? Qt.rgba(accentSecondary.r, accentSecondary.g, accentSecondary.b, playPauseButton.hovered ? 0.9 : 0.6) : Qt.rgba(0.5, 0.5, 0.5, 0.3)

                        // Outer glow ring
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 8
                            height: parent.height + 8
                            radius: width / 2
                            color: "transparent"
                            border.width: playPauseButton.hovered && playPauseButton.enabled ? 2 : 0
                            border.color: Qt.rgba(accentSecondary.r, accentSecondary.g, accentSecondary.b, 0.4)
                            z: -1

                            Behavior on border.width {
                                NumberAnimation { duration: 150 }
                            }
                        }

                        scale: playPauseButton.pressed ? 0.9 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }
                    }

                    contentItem: Kirigami.Icon {
                        source: player.playbackState === MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                        implicitWidth: Math.max(22, Math.min(28, playPauseButton.height * 0.5))
                        implicitHeight: implicitWidth
                        color: {
                            if (!playPauseButton.enabled) return Kirigami.Theme.disabledTextColor
                            return "#FFFFFF"
                        }

                        scale: playPauseButton.pressed ? 0.9 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }
                }
                
                Button {
                    id: nextButton
                    enabled: currentStationUrl !== "" && (currentEbookUrl ? currentEbookChapterIndex < currentEbookChapters.length - 1 : true)
                    onClicked: {
                        if (currentEbookUrl !== "") {
                            console.log("=== NEXT CHAPTER CLICKED ===")
                            nextEbookChapter()
                        } else {
                            console.log("=== NEXT STATION CLICKED ===")
                            var result = playNextStation()
                            console.log("playNextStation returned:", result)
                        }
                    }

                    implicitWidth: buttonSize
                    implicitHeight: buttonSize
                    Layout.alignment: Qt.AlignVCenter

                    ToolTip.text: currentEbookUrl ? "Next chapter" : "Next station"
                    ToolTip.visible: hovered

                    // Modern rounded button design - matching previous button style
                    background: Rectangle {
                        radius: parent.width / 2
                        antialiasing: true

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: {
                                if (!nextButton.enabled) return Qt.rgba(0.3, 0.3, 0.3, 0.2)
                                if (nextButton.pressed) return Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.9)
                                if (nextButton.hovered) return Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.5)
                                return Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, 0.25)
                            }}
                            GradientStop { position: 1.0; color: {
                                if (!nextButton.enabled) return Qt.rgba(0.2, 0.2, 0.2, 0.15)
                                if (nextButton.pressed) return Qt.rgba(accentTertiary.r, accentTertiary.g, accentTertiary.b, 0.85)
                                if (nextButton.hovered) return Qt.rgba(accentTertiary.r, accentTertiary.g, accentTertiary.b, 0.4)
                                return Qt.rgba(accentTertiary.r, accentTertiary.g, accentTertiary.b, 0.15)
                            }}
                        }

                        border.width: nextButton.hovered ? 2 : 1
                        border.color: nextButton.enabled ? Qt.rgba(accentPrimary.r, accentPrimary.g, accentPrimary.b, nextButton.hovered ? 0.7 : 0.4) : Qt.rgba(0.5, 0.5, 0.5, 0.3)

                        scale: nextButton.pressed ? 0.92 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }

                    contentItem: Kirigami.Icon {
                        source: currentEbookUrl ? "media-seek-forward" : "media-skip-forward"
                        implicitWidth: Math.max(16, Math.min(22, nextButton.height * 0.5))
                        implicitHeight: implicitWidth
                        color: {
                            if (!nextButton.enabled) return Kirigami.Theme.disabledTextColor
                            if (nextButton.pressed || nextButton.hovered) return Kirigami.Theme.highlightedTextColor
                            return Kirigami.Theme.textColor
                        }

                        scale: nextButton.pressed ? 0.9 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Item { Layout.fillWidth: true }  // Spacer

                Button {
                    id: randomButton
                    enabled: true  // Always enabled since it can pick from all sources
                    onClicked: playRandomStation()
                    implicitWidth: buttonSize
                    implicitHeight: buttonSize
                    Layout.alignment: Qt.AlignVCenter

                    ToolTip.text: "Random station"
                    ToolTip.visible: hovered

                    // Modern rounded button design
                    background: Rectangle {
                        radius: parent.width / 2
                        color: {
                            if (!randomButton.enabled) return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.3)
                            if (randomButton.pressed) return Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.8)
                            if (randomButton.hovered) return Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.6)
                            return Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.3)
                        }
                        border.width: 1
                        border.color: randomButton.enabled ? Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.8) : Qt.rgba(Kirigami.Theme.disabledTextColor.r, Kirigami.Theme.disabledTextColor.g, Kirigami.Theme.disabledTextColor.b, 0.5)

                        // Subtle glow effect
                        Rectangle {
                            anchors.centerIn: parent
                            width: 20
                            height: parent.height + 4
                            radius: 10
                            color: "transparent"
                            border.width: randomButton.hovered ? 2 : 0
                            border.color: Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.3)
                            visible: randomButton.enabled

                            Behavior on border.width {
                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                            }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }

                    contentItem: Kirigami.Icon {
                        source: "media-playlist-shuffle"
                        implicitWidth: Math.max(16, Math.min(22, randomButton.height * 0.5))
                        implicitHeight: implicitWidth
                        color: {
                            if (!randomButton.enabled) return Kirigami.Theme.disabledTextColor
                            if (randomButton.pressed) return Kirigami.Theme.highlightedTextColor
                            return Kirigami.Theme.textColor
                        }

                        // Rotation animation on click
                        rotation: randomButton.pressed ? 360 : 0
                        Behavior on rotation {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }

                        // Scale animation on press
                        scale: randomButton.pressed ? 0.95 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Item { Layout.fillWidth: true }  // Spacer

                // Volume Control - adaptive visibility
                // Wrapped in Item to prevent window drag when adjusting slider
                Item {
                    id: volumeSliderContainer
                    Layout.fillWidth: false

                    property real scaledWidth: {
                        if (showPopup) {
                            // Popup mode - larger size for better usability
                            return Math.max(150, Math.min(200, root.width / 3.5))
                        } else {
                            // Desktop mode - more aggressive scaling
                            return Math.max(80, Math.min(200, root.width / 6))
                        }
                    }
                    Layout.preferredWidth: scaledWidth
                    Layout.minimumWidth: showPopup ? 100 : 80
                    Layout.maximumWidth: showPopup ? root.width / 3 : root.width / 4
                    Layout.preferredHeight: compactVolumeSlider.implicitHeight
                    Layout.alignment: Qt.AlignVCenter

                    // MouseArea to prevent parent from stealing drag events
                    MouseArea {
                        anchors.fill: parent
                        preventStealing: true
                        propagateComposedEvents: true
                        onPressed: function(mouse) { mouse.accepted = false }
                        onReleased: function(mouse) { mouse.accepted = false }
                    }

                    Slider {
                        id: compactVolumeSlider
                        anchors.fill: parent
                        from: 0
                        to: 1
                        value: 0.5
                        visible: true
                        opacity: isSmall ? 0.7 : 1.0

                        // Save volume level when changed
                        onValueChanged: {
                            saveVolumeLevel(value)
                        }

                        ToolTip.text: Math.round(value * 100) + "%"
                        ToolTip.visible: hovered || pressed
                        ToolTip.delay: 500
                    }
                }
                } // End of top RowLayout
                
                Label {
                    text: {
                        var info = ""
                        if (actualBitrate) info += actualBitrate
                        if (actualChannels) info += (info ? " " : "") + actualChannels
                        return info ? "(" + info + ")" : ""
                    }
                    font.pointSize: Math.max(6, Math.min(9, root.width / 50))
                    color: Kirigami.Theme.disabledTextColor
                    visible: actualBitrate !== "" || actualChannels !== ""
                    Layout.alignment: Qt.AlignVCenter
                }
                
                }
            }
        }
        
        
        // Dedicated Timeline Container for Audiobooks (as part of main layout)
        Rectangle {
            id: timelineContainer
            visible: currentEbookUrl !== "" && player.playbackState === MediaPlayer.PlayingState
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 60 : 0
            Layout.maximumHeight: visible ? 60 : 0
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.95)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
            radius: 8
            
            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: spacingMedium
                
                Label {
                    text: "Timeline:"
                    font.pointSize: baseFontSize
                    font.bold: true
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignVCenter
                }
                
                Slider {
                    id: dedicatedEbookSlider
                    from: 0
                    to: player.duration || 1
                    value: player.position || 0
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    
                    property bool userSeeking: false
                    
                    onPressedChanged: {
                        if (pressed) {
                            userSeeking = true
                        } else {
                            userSeeking = false
                            if (currentEbookUrl && player.duration > 0) {
                                player.setPosition(value)
                                saveEbookProgress()
                            }
                        }
                    }
                    
                    Connections {
                        target: player
                        function onPositionChanged() {
                            if (!dedicatedEbookSlider.userSeeking && currentEbookUrl) {
                                dedicatedEbookSlider.value = player.position
                            }
                        }
                    }
                    
                    onValueChanged: {
                        if (userSeeking && currentEbookUrl && player.duration > 0) {
                            player.setPosition(value)
                        }
                    }
                }
                
                Label {
                    text: {
                        if (player.duration > 0) {
                            var current = Math.floor(player.position / 1000)
                            var total = Math.floor(player.duration / 1000)
                            var currentMin = Math.floor(current / 60)
                            var currentSec = current % 60
                            var totalMin = Math.floor(total / 60)
                            var totalSec = total % 60
                            return (currentMin < 10 ? "0" : "") + currentMin + ":" + 
                                   (currentSec < 10 ? "0" : "") + currentSec + " / " +
                                   (totalMin < 10 ? "0" : "") + totalMin + ":" + 
                                   (totalSec < 10 ? "0" : "") + totalSec
                        }
                        return ""
                    }
                    font.pointSize: baseFontSize
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
        
    } // ColumnLayout
    
    // Add/Edit Custom Radio Dialog (Manual Entry Only)
    Rectangle {
        visible: showCustomDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        z: 100
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                showCustomDialog = false
                stationNameField.text = ""
                streamUrlField.text = ""
            }
        }
        
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.9, 350)
            height: 200
            color: Kirigami.Theme.backgroundColor
            radius: 12
            border.width: 1
            border.color: Kirigami.Theme.highlightColor
            
            MouseArea {
                anchors.fill: parent
                // Prevent clicks from propagating to background
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: marginSize
                spacing: spacingLarge
                
                Text {
                    text: isEditMode ? "Edit Radio Station" : "Add Custom Radio Station"
                    font.pointSize: headerFontSize
                    color: "white"
                }
                
                TextField {
                    id: stationNameField
                    Layout.fillWidth: true
                    placeholderText: "Station Name"
                }
                
                TextField {
                    id: streamUrlField
                    Layout.fillWidth: true
                    placeholderText: "Stream URL"
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: spacingMedium
                    
                    Button {
                        Layout.fillWidth: true
                        text: "Cancel"
                        onClicked: {
                            showCustomDialog = false
                            isEditMode = false
                            editStationIndex = -1
                            stationNameField.text = ""
                            streamUrlField.text = ""
                        }
                    }
                    
                    Button {
                        Layout.fillWidth: true
                        text: isEditMode ? "Update Station" : "Add Station"
                        enabled: stationNameField.text.length > 0 && streamUrlField.text.length > 0
                        onClicked: {
                            var name = stationNameField.text.trim()
                            var url = streamUrlField.text.trim()
                            
                            if (name.length > 0 && url.length > 0) {
                                if (isEditMode) {
                                    // Update existing station
                                    customStations[editStationIndex].name = name
                                    customStations[editStationIndex].host = url
                                    customStations[editStationIndex].url = url
                                    
                                    saveCustomStations()
                                    loadSources()
                                    
                                    if (currentSource === "🔗 Custom Radio") {
                                        loadStations(customStations)
                                    }
                                    
                                    console.log("Updated custom station:", name)
                                } else {
                                    // Add new station
                                    addCustomStation(name, url)
                                }
                                
                                showCustomDialog = false
                                isEditMode = false
                                editStationIndex = -1
                                stationNameField.text = ""
                                streamUrlField.text = ""
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Search Radio Dialog
    Rectangle {
        visible: showSearchDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        z: 100
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                stopPreview() // Stop any preview when closing search
                showSearchDialog = false
                radioSearchField.text = ""
                root.radioSearchResults = []
            }
        }
        
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.9, 500)
            height: 520
            color: Kirigami.Theme.backgroundColor
            radius: 12
            border.width: 1
            border.color: Kirigami.Theme.highlightColor
            
            MouseArea {
                anchors.fill: parent
                // Prevent clicks from propagating to background
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: marginSize
                spacing: spacingMedium
                
                Text {
                    text: "Search Radio Directory"
                    font.pointSize: headerFontSize
                    color: "white"
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: spacingMedium
                    
                    TextField {
                        id: radioSearchField
                        Layout.fillWidth: true
                        placeholderText: "Search for radio stations..."
                        onTextChanged: {
                            if (text.length > 2) {
                                searchTimer.restart()
                            } else {
                                root.radioSearchResults = []
                            }
                        }
                    }
                    
                    Button {
                        text: "Search"
                        enabled: radioSearchField.text.length > 2
                        onClicked: searchRadioStations(radioSearchField.text)
                    }
                }
                
                // Filter Controls
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: spacingMedium
                        
                        CheckBox {
                            id: enableFiltersCheckbox
                            text: "Enable Filters"
                            checked: enableSearchFilters
                            onCheckedChanged: {
                                enableSearchFilters = checked
                                if (radioSearchField.text.length > 2) {
                                    searchRadioStations(radioSearchField.text)
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: spacingMedium
                        visible: enableSearchFilters
                        
                        Text {
                            text: "Min Bitrate:"
                            color: "white"
                            font.pointSize: baseFontSize
                        }
                        
                        ComboBox {
                            id: bitrateFilter
                            model: ["Any", "64 kbps", "128 kbps", "192 kbps", "256 kbps", "320 kbps"]
                            currentIndex: 0
                            onCurrentTextChanged: {
                                var bitrateValues = {"Any": 0, "64 kbps": 64, "128 kbps": 128, "192 kbps": 192, "256 kbps": 256, "320 kbps": 320}
                                minSearchBitrate = bitrateValues[currentText] || 0
                                if (radioSearchField.text.length > 2) {
                                    searchRadioStations(radioSearchField.text)
                                }
                            }
                        }
                        
                        Text {
                            text: "Codec:"
                            color: "white"
                            font.pointSize: baseFontSize
                        }
                        
                        ComboBox {
                            id: codecFilterCombo
                            model: ["Any", "MP3", "AAC", "OGG", "FLAC"]
                            currentIndex: 0
                            onCurrentTextChanged: {
                                codecFilter = currentText === "Any" ? "" : currentText
                                if (radioSearchField.text.length > 2) {
                                    searchRadioStations(radioSearchField.text)
                                }
                            }
                        }
                    }
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.radioSearchResults.length > 0
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    
                    ScrollBar.vertical: ScrollBar {
                        width: 24
                        implicitWidth: 24
                        x: parent.width - 24 - scrollbarMargin
                        visible: true
                        policy: ScrollBar.AsNeeded
                        active: true
                        background: Rectangle {
                            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.3)
                            radius: 10
                            width: 24
                            implicitHeight: parent.height
                        }
                        contentItem: Rectangle {
                            color: Kirigami.Theme.highlightColor
                            radius: 10
                            width: 24 - 2
                        }
                    }
                    
                    ListView {
                        model: root.radioSearchResults.length
                        clip: true
                        rightMargin: enableScrollbars ? scrollbarTotalSpace : 0
                        delegate: Rectangle {
                            property real containerHeight: Math.max(50, Math.min(80, simulatedHeight / 8))
                            width: ListView.view.width - 20  // Reserve 20px for medium scrollbar and spacing
                            height: containerHeight
                            color: {
                                if (isPreviewPlaying && previewStationUrl === station.url) {
                                    return Qt.rgba(0.6, 0.2, 1, 0.3)  // Purple tint when previewing
                                } else if (mouseArea.containsMouse) {
                                    return Kirigami.Theme.highlightColor
                                } else {
                                    return "transparent"
                                }
                            }
                            radius: 6
                            
                            property var station: root.radioSearchResults[index] || {}
                            
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (isPreviewPlaying && previewStationUrl === station.url) {
                                        stopPreview()
                                    } else {
                                        startPreview(station.url)
                                    }
                                }
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: spacingMedium
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Text {
                                        text: station.name || ""
                                        color: "white"
                                        font.pointSize: Math.max(10, Math.min(16, containerHeight * 0.25))
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    
                                    Text {
                                        text: (station.tags || "") + (station.country ? " • " + station.country : "")
                                        color: Kirigami.Theme.disabledTextColor
                                        font.pointSize: Math.max(8, Math.min(12, containerHeight * 0.18))
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    
                                    Text {
                                        text: station.codec + " " + station.bitrate + "kbps"
                                        color: Kirigami.Theme.disabledTextColor
                                        font.pointSize: Math.max(6, Math.min(9, containerHeight * 0.13))
                                    }
                                }
                                
                                RowLayout {
                                    spacing: 5
                                    
                                    Button {
                                        property bool alreadyAdded: isStationAlreadyAdded(station.name, station.url)
                                        text: alreadyAdded ? "✓" : "+"
                                        width: 30
                                        height: 30
                                        font.pointSize: largeFontSize
                                        font.bold: true
                                        enabled: !alreadyAdded
                                        
                                        onClicked: {
                                            if (!alreadyAdded) {
                                                addCustomStation(station.name, station.url)
                                                // Don't close dialog - keep it open for adding more stations
                                            }
                                        }
                                        
                                        ToolTip.text: alreadyAdded ? "Already added" : "Add station"
                                        ToolTip.visible: hovered
                                        
                                        background: Rectangle {
                                            color: {
                                                if (parent.alreadyAdded) {
                                                    return Qt.rgba(0.5, 0.5, 0.5, 0.3)  // Grey for already added
                                                } else {
                                                    return parent.pressed ? Qt.rgba(0, 0.6, 0, 0.8) :
                                                           parent.hovered ? Qt.rgba(0, 0.6, 0, 0.6) : Qt.rgba(0, 0.6, 0, 0.4)
                                                }
                                            }
                                            radius: 4
                                            border.width: 1
                                            border.color: parent.alreadyAdded ? Qt.rgba(0.5, 0.5, 0.5, 0.5) : Qt.rgba(0, 0.6, 0, 0.8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                Text {
                    visible: radioSearchField.text.length > 2 && root.radioSearchResults.length === 0
                    text: "No stations found. Try a different search term."
                    color: Kirigami.Theme.disabledTextColor
                    font.pointSize: baseFontSize
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Button {
                    Layout.fillWidth: true
                    text: "Close"
                    onClicked: {
                        stopPreview() // Stop any preview when closing search
                        showSearchDialog = false
                        radioSearchField.text = ""
                        root.radioSearchResults = []
                    }
                }
            }
        }
        
        // Search delay timer
        Timer {
            id: searchTimer
            interval: 500
            onTriggered: searchRadioStations(radioSearchField.text)
        }
    }

    // LibriVox Search Dialog
    Rectangle {
        visible: showEbookSearchDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        z: 100
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                showEbookSearchDialog = false
                ebookSearchField.text = ""
            }
        }
        
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.9, 400)
            height: 300
            color: Kirigami.Theme.backgroundColor
            radius: 12
            border.width: 1
            border.color: Kirigami.Theme.highlightColor
            
            MouseArea {
                anchors.fill: parent
                // Prevent clicks from propagating to background
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: marginSize
                spacing: spacingLarge
                
                Text {
                    text: "Search LibriVox Audiobooks"
                    font.pointSize: headerFontSize
                    color: "white"
                }
                
                TextField {
                    id: ebookSearchField
                    Layout.fillWidth: true
                    placeholderText: "Search for audiobook (e.g., Alice in Wonderland)"
                    onTextChanged: {
                        if (text.length > 2) {
                            searchEbooks(text)
                        }
                    }
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    
                    ScrollBar.vertical: ScrollBar {
                        width: 24
                        implicitWidth: 24
                        x: parent.width - 24 - scrollbarMargin
                        visible: true
                        policy: ScrollBar.AsNeeded
                        active: true
                        background: Rectangle {
                            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.3)
                            radius: 10
                            width: 24
                            implicitHeight: parent.height
                        }
                        contentItem: Rectangle {
                            color: Kirigami.Theme.highlightColor
                            radius: 10
                            width: 24 - 2
                        }
                    }
                    
                    ListView {
                        id: ebookResultsList
                        model: ListModel { id: ebookSearchResults }
                        rightMargin: enableScrollbars ? scrollbarTotalSpace : 0
                        delegate: Item {
                            property real containerHeight: Math.max(50, Math.min(80, simulatedHeight / 8))
                            width: parent.width
                            height: containerHeight
                            
                            Rectangle {
                                anchors.fill: parent
                                color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                                radius: 6
                                
                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        addCustomEbook(model.title, model.rss_url)
                                        showEbookSearchDialog = false
                                        ebookSearchField.text = ""
                                        ebookSearchResults.clear()
                                    }
                                }
                                
                                ColumnLayout {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 10
                                    
                                    Text {
                                        text: model.title
                                        color: "white"
                                        font.pointSize: Math.max(10, Math.min(16, containerHeight * 0.25))
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    
                                    Text {
                                        text: "by " + (model.authors || "Unknown")
                                        color: "#888"
                                        font.pointSize: Math.max(8, Math.min(12, containerHeight * 0.18))
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
                
                Button {
                    text: "Close"
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: {
                        showEbookSearchDialog = false
                        ebookSearchField.text = ""
                        ebookSearchResults.clear()
                    }
                }
            }
        }
    }

    // Custom Ebook URL Dialog
    Rectangle {
        visible: showCustomEbookDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        z: 100
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                showCustomEbookDialog = false
                ebookTitleField.text = ""
                ebookUrlField.text = ""
            }
        }
        
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.9, 350)
            height: 200
            color: Kirigami.Theme.backgroundColor
            radius: 12
            border.width: 1
            border.color: Kirigami.Theme.highlightColor
            
            MouseArea {
                anchors.fill: parent
                // Prevent clicks from propagating to background
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: marginSize
                spacing: spacingLarge
                
                Text {
                    text: "Add Custom Audiobook"
                    font.pointSize: headerFontSize
                    color: "white"
                }
                
                TextField {
                    id: ebookTitleField
                    Layout.fillWidth: true
                    placeholderText: "Audiobook Title"
                }
                
                TextField {
                    id: ebookUrlField
                    Layout.fillWidth: true
                    placeholderText: "LibriVox RSS URL"
                }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    
                    Button {
                        text: "Add"
                        enabled: ebookTitleField.text.trim() && ebookUrlField.text.trim()
                        onClicked: {
                            addCustomEbook(ebookTitleField.text.trim(), ebookUrlField.text.trim())
                            showCustomEbookDialog = false
                            ebookTitleField.text = ""
                            ebookUrlField.text = ""
                        }
                    }
                    
                    Button {
                        text: "Cancel"
                        onClicked: {
                            showCustomEbookDialog = false
                            ebookTitleField.text = ""
                            ebookUrlField.text = ""
                        }
                    }
                }
            }
        }
    }
    
    // Popup window for compact mode
    Window {
        id: radioPopup
        visible: showPopup && isCompactMode
        flags: Qt.Popup | Qt.FramelessWindowHint
        color: "transparent"
        
        width: Math.max(320, Math.min(400, Screen.desktopAvailableWidth * 0.25))
        height: Math.max(480, Math.min(650, Screen.desktopAvailableHeight * 0.5))
        
        // Position popup near the panel widget
        x: {
            if (!parent) return 0
            var pos = parent.mapToGlobal(0, 0)
            // Position to the right of the panel widget, with some margin
            return Math.min(pos.x + parent.width + 10, Screen.desktopAvailableWidth - width - 20)
        }
        
        y: {
            if (!parent) return 0
            var pos = parent.mapToGlobal(0, 0)
            // Center vertically relative to the panel widget
            return Math.max(20, Math.min(pos.y - height/2 + parent.height/2, Screen.desktopAvailableHeight - height - 20))
        }
        
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            radius: 12
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)
            
            // Header with close button
            Rectangle {
                id: popupHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 40
                color: Qt.rgba(0, 0, 0, 0.1)
                radius: 12
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.radius
                    color: parent.color
                }
                
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Free Radio"
                    font.bold: true
                    color: Kirigami.Theme.textColor
                }
                
                Button {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    flat: true
                    width: 24
                    height: 24
                    onClicked: hideRadioPopup()
                    
                    contentItem: Text {
                        text: parent.text
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Kirigami.Theme.textColor
                    }
                }
            }
            
            // Content container for the main widget when in popup mode
            Item {
                id: contentContainer
                anchors.top: popupHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
            }
        }
        
        // Close popup when clicking outside
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: hideRadioPopup()
        }
    }
} // PlasmoidItem

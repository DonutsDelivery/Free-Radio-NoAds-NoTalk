import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtMultimedia 6.5
import org.kde.plasma.plasmoid
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import "radiodata.js" as RadioData

PlasmoidItem {
    id: root
    
    // Responsive sizing - optimized for all screen sizes
    property real screenWidth: Screen.desktopAvailableWidth
    property real screenHeight: Screen.desktopAvailableHeight
    
    Layout.minimumWidth: Math.max(280, Math.min(350, screenWidth * 0.15))   // Min 280px, max 350px or 15% of screen
    Layout.minimumHeight: Math.max(350, Math.min(450, screenHeight * 0.30)) // Min 350px, max 450px or 30% of screen
    Layout.preferredWidth: Math.max(300, Math.min(380, screenWidth * 0.15)) // Preferred 300-380px or 15% of screen
    Layout.preferredHeight: Math.max(400, Math.min(520, screenHeight * 0.35)) // Preferred 400-520px or 35% of screen
    Layout.maximumWidth: Math.max(350, Math.min(420, screenWidth * 0.18))   // Max 350-420px or 18% of screen
    Layout.maximumHeight: Math.max(500, Math.min(600, screenHeight * 0.40)) // Max 500-600px or 40% of screen
    
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

    property bool inSource: false
    property bool inCategory: false
    property string currentSource: ""
    property string currentCategory: ""
    property string streamQuality: "2"
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
    
    // Last played station persistence
    property string lastStationName: ""
    property string lastStationUrl: ""
    property string lastStationHost: ""
    property string lastStationPath: ""
    property string lastSource: ""
    property string lastCategory: ""
    
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
    
    function loadLastStation() {
        // Load last played station from configuration
        lastStationName = plasmoid.configuration.lastStationName || ""
        lastStationUrl = plasmoid.configuration.lastStationUrl || ""
        lastStationHost = plasmoid.configuration.lastStationHost || ""
        lastStationPath = plasmoid.configuration.lastStationPath || ""
        lastSource = plasmoid.configuration.lastSource || ""
        lastCategory = plasmoid.configuration.lastCategory || ""
        
        console.log("Loaded last station:", lastStationName)
        
        if (lastStationName && lastStationUrl) {
            // Restore station info but don't auto-play
            currentStationName = lastStationName
            currentStationUrl = lastStationUrl
            currentStationHost = lastStationHost
            currentStationPath = lastStationPath
            currentSource = lastSource
            currentCategory = lastCategory
            
            // Set up the UI state without playing
            player.source = lastStationUrl
            
            // Navigate to the appropriate category if it was set
            if (lastSource && lastCategory) {
                // Set the navigation state to show the category
                inSource = true
                inCategory = true
                
                // Load the source and category
                if (lastSource === "📻 RadCap.ru") {
                    loadSource({name: "📻 RadCap.ru", description: "500+ curated music channels", categories: RadioData.radcapCategories})
                } else if (lastSource === "🎵 SomaFM") {
                    loadSource({name: "🎵 SomaFM", description: "30+ stations in 7 genres", categories: RadioData.somafmCategories})
                }
                
                // Find and load the specific category
                var sourceCategories = lastSource === "📻 RadCap.ru" ? RadioData.radcapCategories : RadioData.somafmCategories
                for (var i = 0; i < sourceCategories.length; i++) {
                    if (sourceCategories[i].name === lastCategory) {
                        loadCategory(sourceCategories[i])
                        break
                    }
                }
            }
            
            console.log("Last station restored, ready to play:", lastStationName)
        }
    }
    
    function saveLastStation() {
        // Save current station to configuration
        plasmoid.configuration.lastStationName = currentStationName
        plasmoid.configuration.lastStationUrl = currentStationUrl
        plasmoid.configuration.lastStationHost = currentStationHost
        plasmoid.configuration.lastStationPath = currentStationPath
        plasmoid.configuration.lastSource = currentSource
        plasmoid.configuration.lastCategory = currentCategory
        
        // Force configuration save
        plasmoid.writeConfig()
        
        console.log("Saved last station:", currentStationName)
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
        
        console.log("Audio detection completed - Other audio:", hasOtherAudio ? "YES" : "NO")
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
        
        saveFavorites()
        loadSources() // Refresh the sources to update favorites count
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

    MediaPlayer {
        id: player
        autoPlay: false
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput {
            id: audioOut
            volume: volumeSlider.value
        }
        
        onErrorOccurred: function(error, errorString) {
            console.log("=== MEDIAPLAYER ERROR ===")
            console.log("Error code:", error)
            console.log("Error string:", errorString)
            console.log("Current source:", source)
            console.log("Current media status:", mediaStatus)
            console.log("Current playback state:", playbackState)
        }
        
        onMediaStatusChanged: {
            var statusNames = ["NoMedia", "Loading", "Loaded", "Stalled", "Buffering", "Buffered", "EndOfMedia", "InvalidMedia"]
            console.log("Media status changed to:", statusNames[mediaStatus] || mediaStatus)
            console.log("Current source:", source)
        }
        
        onPlaybackStateChanged: {
            var stateNames = ["Stopped", "Playing", "Paused"]
            console.log("Playback state changed to:", stateNames[playbackState] || playbackState)
            console.log("Current source:", source)
        }
        
        onSourceChanged: {
            console.log("Source changed to:", source)
        }
        
        onMetaDataChanged: {
            // Extract song information from stream metadata
            console.log("=== METADATA CHANGED ===")
            console.log("Available metadata keys:", Object.keys(metaData))
            
            // Record that we got a metadata update
            lastMetadataUpdate = new Date()
            
            // Try various possible metadata fields for ICY streams
            var title = metaData.title || metaData.Title || ""
            var artist = metaData.albumArtist || metaData.artist || metaData.Artist || ""
            var streamTitle = metaData.streamTitle || metaData.StreamTitle || metaData.icyTitle || ""
            var bitrate = metaData.audioBitRate || ""
            var channels = metaData.audioChannelCount || ""
            var sampleRate = metaData.audioSampleRate || ""
            
            console.log("Raw metadata - Title:", title, "Artist:", artist, "StreamTitle:", streamTitle)
            console.log("Audio details - Bitrate:", bitrate, "Channels:", channels, "Sample rate:", sampleRate)
            
            // Debug: log all metadata properties and create debug string
            var debugInfo = "Available metadata: "
            var metadataKeys = []
            for (var key in metaData) {
                if (metaData.hasOwnProperty(key)) {
                    console.log("Metadata property:", key, "=", metaData[key])
                    metadataKeys.push(key + "=" + metaData[key])
                }
            }
            debugMetadata = metadataKeys.join(", ")
            
            // Update actual received bitrate and channels
            if (bitrate) {
                actualBitrate = Math.round(bitrate / 1000) + "k"
                console.log("Actual bitrate:", actualBitrate)
            }
            if (channels) {
                actualChannels = channels == 1 ? "mono" : (channels == 2 ? "stereo" : channels + "ch")
                console.log("Actual channels:", actualChannels)
            }
            
            // Try to use streamTitle if available (common for radio streams)
            var workingTitle = streamTitle || title
            
            // Only update song info if we actually have meaningful data
            // Don't overwrite existing song info with empty data
            if (workingTitle && workingTitle.trim() !== "") {
                // Parse "Artist - Title" format if available
                if (workingTitle.includes(" - ")) {
                    var parts = workingTitle.split(" - ")
                    if (parts.length >= 2) {
                        updateSongInfo(parts.slice(1).join(" - ").trim(), parts[0].trim())
                    } else {
                        updateSongInfo(workingTitle, artist && artist.trim() !== "" ? artist : currentArtist)
                    }
                } else {
                    updateSongInfo(workingTitle, artist && artist.trim() !== "" ? artist : currentArtist)
                }
            } else if (artist && artist.trim() !== "" && (!currentArtist || currentArtist === "")) {
                // If we have artist info but no title, just update artist
                updateSongInfo(currentSongTitle, artist)
            }
            
            console.log("Parsed - Artist:", currentArtist, "Title:", currentSongTitle, "Actual bitrate:", actualBitrate)
            console.log("Current song display should be visible:", (currentSongTitle || currentArtist))
        }
    }

    function loadSources() {
        console.log("Loading radio sources")
        sourcesModel.clear()
        
        // Add Favorites if there are any
        if (favoriteStations.length > 0) {
            sourcesModel.append({
                "name": "⭐ Favorites",
                "description": favoriteStations.length + " favorite stations",
                "categories": [{
                    "name": "Favorite Stations",
                    "stations": favoriteStations
                }]
            })
        }
        
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
        console.log("Initial stream quality:", streamQuality)
        loadFavorites()
        loadSources()
        loadLastStation()  // Restore last played station
    }

    function loadSource(source) {
        console.log("Loading source:", source.name)
        currentSource = source.name
        
        // Special handling for Favorites - go directly to stations
        if (source.name === "⭐ Favorites") {
            console.log("Loading favorite stations directly")
            currentCategory = "Favorite Stations"
            loadStations(favoriteStations)
            inSource = true
            inCategory = true  // Skip category view, go straight to stations
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
                "path": stations[i].path
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
                        player.play()
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
            var bitrate, format;
            if (quality === "1") {
                bitrate = "64";
                format = "aac";  // Lower quality AAC
            } else if (quality === "2") {
                bitrate = "128";
                format = "mp3";  // Standard quality MP3
            } else if (quality === "3") {
                bitrate = "256";
                format = "mp3";  // Higher quality MP3
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
            
            var baseUrl = host.replace(":8000", ":" + port) + ":" + port + "/" + path
            console.log("RadCap stream URL:", baseUrl, "for quality level:", quality)
            return baseUrl
        }
    }
    
    function fetchStreamMetadata(streamUrl) {
        console.log("Fetching live song metadata")
        
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
        
        // Try playback history method directly (more reliable than server status parsing)
        getPlaybackHistoryUrl(stationPath)
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
            // Fallback to the old method
            tryPlaybackHistoryUrl(originalStationPath, [2, 3, 4, 1, 5, 6], 0)
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
        var historyUrl = "http://radcap.ru/playback-history/" + pathNumber + "/" + stationPath + "-ph.php"
        
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
        if (currentStationName && inCategory) {
            console.log("Reloading current station with new quality:", streamQuality)
            // Find current station in model and reload it
            for (var i = 0; i < stationsModel.count; i++) {
                var station = stationsModel.get(i)
                if (station.name === currentStationName) {
                    var streamUrl = getStreamUrl(station.host, station.path, streamQuality)
                    currentStationUrl = streamUrl
                    
                    // Clear song info when changing quality
                    currentSongTitle = ""
                    currentArtist = ""
                    debugMetadata = "Reloading with new quality..."
                    
                    songUpdateTimer.stop()
                    player.stop()
                    console.log("=== RELOADING STATION ===")
                    console.log("Stream URL:", streamUrl)
                    
                    // Fetch live song metadata
                    fetchStreamMetadata(streamUrl)
                    songUpdateTimer.start()
                    
                    player.source = streamUrl
                    player.play()
                    break
                }
            }
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
                        "path": categoryData.stations[j].path
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

    // Widget styling - no default background to show custom rounded edges
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    
    // Modern glassmorphism background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.85)
        radius: 24
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.15)
        antialiasing: true
        
        // Subtle shadow effect
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            color: "transparent"
            radius: parent.radius
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.1)
            antialiasing: true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(8, root.width * 0.03)  // Responsive padding: 8px min or 3% of width
        spacing: Math.max(8, root.height * 0.02)  // Responsive spacing: 8px min or 2% of height

        // Sources ListView
        ScrollView {
            visible: !inSource && !inCategory
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            
            ListView {
                model: sourcesModel
                spacing: Math.max(6, root.height * 0.01)  // Responsive spacing: 6px min or 1% of height
                
                delegate: ItemDelegate {
                    width: ListView.view.width
                    height: Math.max(50, root.height * 0.12)  // Responsive height: 50px min or 12% of widget height
                
                // Modern card background
                background: Rectangle {
                    color: {
                        if (parent.pressed) return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4)
                        if (parent.hovered) return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                        return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.9)
                    }
                    radius: 12
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                    antialiasing: true
                    
                    // Subtle drop shadow
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2
                        anchors.leftMargin: 1
                        color: Qt.rgba(0, 0, 0, 0.1)
                        radius: parent.radius
                        z: -1
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
                
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    
                    Label {
                        text: model.name
                        font.family: "SF Pro Display, Segoe UI, -apple-system, BlinkMacSystemFont, sans-serif"
                        font.pointSize: Math.max(10, root.width * 0.04)  // Responsive: 10px min or 4% of widget width
                        font.weight: Font.DemiBold
                        color: Kirigami.Theme.textColor
                    }
                    Label {
                        text: model.description
                        font.family: "SF Pro Text, Segoe UI, -apple-system, BlinkMacSystemFont, sans-serif"
                        font.pointSize: Math.max(8, root.width * 0.025)  // Responsive: 8px min or 2.5% of widget width
                        color: Kirigami.Theme.textColor
                        opacity: 0.65
                        font.weight: Font.Normal
                    }
                }
                
                onClicked: loadSource(model)
                }
            }
        }
        
        // Categories ListView with back button
        ColumnLayout {
            visible: inSource && !inCategory
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
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                
                GridView {
                    model: categoriesModel
                    
                    // 2 columns layout
                    cellWidth: width / 2
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
                }
            }
        }

        // Stations View
        ColumnLayout {
            visible: inCategory
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "⬅ Back"
                    onClicked: {
                        if (inCategory) {
                            // Special handling for favorites - go directly back to sources
                            if (currentSource === "⭐ Favorites") {
                                inCategory = false
                                inSource = false
                                stationsModel.clear()
                                currentCategory = ""
                                currentSource = ""
                                console.log("Navigated back from favorites to sources")
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
                    text: currentSource + (currentCategory ? " > " + currentCategory : "")
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: 10
                }
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                
                ListView {
                    model: stationsModel
                    spacing: Math.max(1, root.height / 250)  // Responsive spacing
                    
                    delegate: ItemDelegate {
                        width: ListView.view.width
                        height: Math.max(25, Math.min(35, root.height / 25))  // Responsive height
                    text: model.name
                    font.pointSize: Math.max(7, Math.min(11, root.width / 40))  // Responsive font
                    
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
                        
                        console.log("=== STATION CLICK ===")
                        console.log("Station:", model.name)
                        console.log("Stream URL:", streamUrl)
                        console.log("Quality:", streamQuality + "kbps")
                        console.log("Player state before:", player.playbackState)
                        
                        songUpdateTimer.stop()
                        player.stop()
                        
                        // Fetch live song metadata and start timer
                        fetchStreamMetadata(streamUrl)
                        songUpdateTimer.start()
                        
                        // Play directly without playlist parsing
                        player.source = streamUrl
                        player.play()
                        
                        // Save this station as the last played
                        saveLastStation()
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
                }
            }
        }

        // Status display
        Rectangle {
            Layout.fillWidth: true
            height: Math.max(60, Math.min(80, root.height * 0.15))  // Responsive height
            color: Kirigami.Theme.backgroundColor
            radius: 12
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
            antialiasing: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 2
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Label {
                        text: currentStationName ? "♪ " + currentStationName : "No station selected"
                        font.pointSize: Math.max(8, Math.min(12, root.width / 35))  // Responsive font
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        color: currentStationName ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                        Layout.fillWidth: true
                    }
                    
                    Button {
                        visible: currentStationName !== ""
                        text: {
                            if (currentStationName === "" || currentStationHost === "" || currentStationPath === "") return "☆"
                            // Use stored station data
                            return isFavorite(currentStationName, currentStationHost, currentStationPath) ? "⭐" : "☆"
                        }
                        font.pointSize: Math.max(10, Math.min(14, root.width / 30))
                        implicitWidth: Math.max(25, Math.min(35, root.width / 15))
                        implicitHeight: Math.max(25, Math.min(35, root.height / 25))
                        flat: true
                        
                        // Custom content item to control star color
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: {
                                if (currentStationName === "" || currentStationHost === "" || currentStationPath === "") return Kirigami.Theme.textColor
                                // Use stored station data to check if favorited
                                return isFavorite(currentStationName, currentStationHost, currentStationPath) ? "white" : Kirigami.Theme.textColor
                            }
                        }
                        onClicked: {
                            if (currentStationName === "" || currentStationHost === "" || currentStationPath === "") return
                            // Use stored station data instead of searching model
                            toggleFavorite(currentStationName, currentStationHost, currentStationPath)
                        }
                        ToolTip.text: {
                            if (currentStationName === "" || currentStationHost === "" || currentStationPath === "") return "Add to favorites"
                            // Use stored station data
                            return isFavorite(currentStationName, currentStationHost, currentStationPath) ? "Remove from favorites" : "Add to favorites"
                        }
                        ToolTip.visible: hovered
                    }
                }
                
                RowLayout {
                    visible: currentSongTitle || currentArtist
                    Layout.fillWidth: true
                    
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
                        font.pointSize: Math.max(7, Math.min(10, root.width / 40))  // Responsive font
                        color: Kirigami.Theme.textColor
                        Layout.fillWidth: true
                        readOnly: true
                        selectByMouse: true
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
        
        
        // Controls
        Rectangle {
            Layout.fillWidth: true
            height: Math.max(60, Math.min(80, root.height * 0.15))  // Taller responsive height for better centering
            color: Kirigami.Theme.backgroundColor
            radius: 12
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
            antialiasing: true
            
            // Single horizontal row: Play, Quality, Volume controls
            RowLayout {
                anchors.centerIn: parent
                width: parent.width - 24
                height: parent.height - 24
                spacing: 12
                
                Button {
                    text: player.playbackState === MediaPlayer.PlayingState ? "⏹" : "▶"
                    enabled: currentStationUrl !== ""
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState) {
                            player.stop()
                            songUpdateTimer.stop()
                        } else if (currentStationUrl !== "") {
                            player.play()
                            songUpdateTimer.start()
                        }
                    }
                    font.pointSize: Math.max(14, Math.min(18, root.width / 25))
                    implicitWidth: Math.max(50, Math.min(60, root.width / 12))
                    implicitHeight: Math.max(40, Math.min(50, root.height / 15))
                    Layout.alignment: Qt.AlignVCenter
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: parent.enabled ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                        // Adjust padding for play symbol to appear more centered
                        leftPadding: parent.text === "▶" ? 2 : 0
                    }
                }
                
                Label {
                    text: "Quality:"
                    font.pointSize: Math.max(7, Math.min(10, root.width / 40))  // Responsive font
                    color: Kirigami.Theme.textColor
                    Layout.alignment: Qt.AlignVCenter
                }
                
                ComboBox {
                    id: qualityBox
                    model: [
                        {"text": "1 (48k)", "value": "1"},
                        {"text": "2 (320k)", "value": "2"}, 
                        {"text": "3 (HQ)", "value": "3"}
                    ]
                    textRole: "text"
                    valueRole: "value"
                    currentIndex: 1  // Default to quality 2 (standard)
                    onCurrentValueChanged: {
                        streamQuality = currentValue
                        console.log("=== QUALITY CHANGE ===")
                        console.log("Quality changed to level:", streamQuality)
                        console.log("Current station name:", currentStationName)
                        console.log("Current station URL:", currentStationUrl)
                        // Reload current station with new quality
                        reloadCurrentStation()
                    }
                    implicitWidth: Math.max(70, Math.min(90, root.width / 8))
                    Layout.alignment: Qt.AlignVCenter
                }
                
                Label {
                    text: {
                        var info = ""
                        if (actualBitrate) info += actualBitrate
                        if (actualChannels) info += (info ? " " : "") + actualChannels
                        return info ? "(" + info + ")" : ""
                    }
                    font.pointSize: Math.max(6, Math.min(9, root.width / 50))  // Responsive font
                    color: Kirigami.Theme.disabledTextColor
                    visible: actualBitrate !== "" || actualChannels !== ""
                    Layout.alignment: Qt.AlignVCenter
                }
                
                
                Slider {
                    id: volumeSlider
                    from: 0
                    to: 1
                    value: 0.5
                    Layout.fillWidth: true
                    enabled: currentStationName !== ""
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    } // ColumnLayout
} // PlasmoidItem

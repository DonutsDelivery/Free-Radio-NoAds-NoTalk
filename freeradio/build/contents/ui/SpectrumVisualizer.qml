import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: spectrumRoot
    
    property var player: null
    property int barCount: 32
    property real barMaxHeight: height * 0.8
    property real barMinHeight: 2
    property real barWidth: (width - (barCount - 1) * spacing) / barCount
    property real spacing: 2
    
    // Audio reactive data
    property var spectrumData: []
    property real currentVolume: 0.5
    property real lastBufferProgress: 0
    property bool isPlaying: false
    
    // Animation properties - optimized for performance
    property real smoothingFactor: 0.3  // Moderate response
    property real decayRate: 0.85       // Faster decay
    property real sensitivity: 1.8      // Moderate sensitivity
    property real bassBoost: 1.4        // Moderate bass emphasis
    
    // Colors
    property color barColor: Kirigami.Theme.highlightColor
    property color peakColor: Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
    
    // Audio analysis using player state and buffer progress
    property real audioActivity: 0
    property real bassLevel: 0
    property real midLevel: 0
    property real trebleLevel: 0
    
    // Initialize spectrum data
    Component.onCompleted: {
        initializeSpectrum()
        audioAnalysisTimer.start()
    }
    
    // Watch for player changes
    onPlayerChanged: {
        if (player) {
            isPlaying = (player.playbackState === MediaPlayer.PlayingState)
            currentVolume = player.volume !== undefined ? player.volume : 0.5
            
            // Connect to player state changes
            player.playbackStateChanged.connect(function() {
                isPlaying = (player.playbackState === MediaPlayer.PlayingState)
                console.log("Spectrum: Player state changed to:", player.playbackState, "isPlaying:", isPlaying)
            })
            
            player.volumeChanged.connect(function() {
                currentVolume = player.volume !== undefined ? player.volume : 0.5
            })
        }
    }
    
    function initializeSpectrum() {
        spectrumData = []
        for (var i = 0; i < barCount; i++) {
            spectrumData.push({
                current: 0,
                peak: 0,
                peakHold: 0,
                target: 0,
                decayCounter: 0,
                frequency: i / barCount
            })
        }
    }
    
    function updateAudioAnalysis() {
        if (!player) {
            isPlaying = false
            return
        }
        
        // More robust player state detection
        var wasPlaying = isPlaying
        isPlaying = (player.playbackState === MediaPlayer.PlayingState)
        currentVolume = player.volume !== undefined ? player.volume : 0.5
        
        // Debug logging when state changes
        if (wasPlaying !== isPlaying) {
            console.log("Spectrum: Playing state changed from", wasPlaying, "to", isPlaying)
            console.log("Spectrum: Player state:", player.playbackState, "Volume:", currentVolume)
        }
        
        if (isPlaying && player && player.source !== "") {
            // Use buffer progress changes to detect audio activity
            var bufferProgress = player.bufferProgress
            var progressDelta = Math.abs(bufferProgress - lastBufferProgress)
            lastBufferProgress = bufferProgress
            
            // Generate audio activity based on playback state and time
            var time = Date.now()
            
            // More realistic activity based on buffer progress changes
            var bufferActivity = progressDelta > 0.001 ? 1.0 : 0.7
            var baseActivity = (Math.random() * 0.4 + 0.6) * bufferActivity
            
            // Only animate if actually playing (not paused)
            if (player.playbackState !== MediaPlayer.PlayingState) {
                baseActivity *= 0.1  // Minimal activity when not playing
            }
            
            // Simplified frequency bands - less CPU intensive
            bassLevel = Math.sin(time * 0.005) * 0.4 + 0.6 + Math.random() * 0.2
            midLevel = Math.sin(time * 0.008 + 1.5) * 0.3 + 0.5 + Math.random() * 0.3
            trebleLevel = Math.sin(time * 0.012 + 3) * 0.2 + 0.4 + Math.random() * 0.3
            
            // Simplified rhythm pattern - less computation
            var rhythmPattern = Math.sin(time * 0.01) * 0.5 + 0.5
            
            audioActivity = baseActivity * rhythmPattern * currentVolume
            
            // Update spectrum bars based on simulated frequency analysis
            for (var i = 0; i < barCount; i++) {
                var frequency = i / barCount
                var magnitude = 0
                
                // Simulate realistic frequency response curve with more variation
                if (frequency < 0.2) {
                    // Sub-bass frequencies (most prominent)
                    magnitude = bassLevel * bassBoost * (1.2 - frequency * 0.3)
                } else if (frequency < 0.4) {
                    // Bass frequencies
                    magnitude = bassLevel * (1.0 - (frequency - 0.2) * 0.8)
                } else if (frequency < 0.6) {
                    // Mid frequencies
                    magnitude = midLevel * (0.9 - Math.abs(frequency - 0.5) * 0.4)
                } else if (frequency < 0.8) {
                    // High-mid frequencies
                    magnitude = (midLevel + trebleLevel) * 0.5 * (0.8 - (frequency - 0.6) * 0.5)
                } else {
                    // Treble frequencies
                    magnitude = trebleLevel * (0.7 - (frequency - 0.8) * 1.5)
                }
                
                // Simplified bar variation - less computation
                var barVariation = Math.sin(time * 0.008 + i * 0.3) * 0.2 + 0.8
                magnitude *= audioActivity * barVariation * (0.9 + Math.random() * 0.2)
                magnitude *= sensitivity
                
                // Smooth the transitions
                spectrumData[i].target = Math.min(1.0, Math.max(0, magnitude))
                spectrumData[i].current = spectrumData[i].current * (1 - smoothingFactor) + 
                                         spectrumData[i].target * smoothingFactor
                
                // Update peak
                if (spectrumData[i].current > spectrumData[i].peak) {
                    spectrumData[i].peak = spectrumData[i].current
                    spectrumData[i].peakHold = spectrumData[i].current
                    spectrumData[i].decayCounter = 0
                } else {
                    spectrumData[i].decayCounter++
                    // Faster peak decay with higher frame rate
                    if (spectrumData[i].decayCounter > 8) {
                        spectrumData[i].peak *= 0.94
                    }
                    spectrumData[i].peakHold *= 0.96
                }
            }
        } else {
            // Aggressive decay when not playing - make bars disappear quickly
            audioActivity *= 0.8
            bassLevel *= 0.7
            midLevel *= 0.7
            trebleLevel *= 0.7
            
            for (var i = 0; i < barCount; i++) {
                spectrumData[i].current *= 0.7  // Faster decay
                spectrumData[i].peak *= 0.8
                spectrumData[i].peakHold *= 0.85
            }
        }
        
        // Trigger visual update with non-blocking approach
        if (!isRendering) {
            isRendering = true
            spectrumCanvas.requestPaint()
        }
    }
    
    // Frame skipping mechanism to prevent audio hiccups
    property bool isRendering: false
    property int skippedFrames: 0
    property int maxSkippedFrames: 3  // Skip max 3 frames to prevent lag
    
    // Audio analysis timer - with frame skipping protection
    Timer {
        id: audioAnalysisTimer
        interval: 100 // 10 FPS - slower to prevent audio blocking
        running: false
        repeat: true
        onTriggered: {
            // Skip rendering if still processing previous frame
            if (isRendering) {
                skippedFrames++
                if (skippedFrames < maxSkippedFrames) {
                    console.log("Spectrum: Frame skipped (" + skippedFrames + "/" + maxSkippedFrames + ")")
                    return // Skip this frame
                }
                // Force render after max skipped frames
                console.log("Spectrum: Forcing render after max skipped frames")
            }
            
            skippedFrames = 0
            updateAudioAnalysis()
        }
    }
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.1)
        radius: 4
    }
    
    // Spectrum bars using GPU-accelerated Canvas for better performance
    Canvas {
        id: spectrumCanvas
        anchors.fill: parent
        
        // Enable GPU acceleration for smooth rendering
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative  // Less aggressive than Threaded
        
        // Performance optimizations
        antialiasing: false  // Disable for better performance
        smooth: false       // Disable for better performance
        
        // Additional optimization properties
        contextType: "2d"
        
        // Cache the canvas when not actively updating
        property bool canvasValid: false
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            
            if (spectrumData.length === 0) {
                isRendering = false
                return
            }
            
            var barWidth = (width - (barCount - 1) * spacing) / barCount
            
            // Pre-calculate colors for performance
            var baseColor = Qt.rgba(barColor.r, barColor.g, barColor.b, 0.9)
            var topColor = Qt.rgba(barColor.r, barColor.g, barColor.b, 0.4)
            var peakColorRgba = Qt.rgba(peakColor.r, peakColor.g, peakColor.b, 0.8)
            
            // Create gradient once and reuse
            var gradient = ctx.createLinearGradient(0, height, 0, 0)
            gradient.addColorStop(0, baseColor)
            gradient.addColorStop(1, topColor)
            
            // Draw all bars in one pass
            ctx.fillStyle = gradient
            for (var i = 0; i < barCount; i++) {
                var x = i * (barWidth + spacing)
                var barHeight = Math.max(barMinHeight, spectrumData[i].current * barMaxHeight)
                
                // Draw main bar
                ctx.fillRect(x, height - barHeight, barWidth, barHeight)
            }
            
            // Draw all peaks in separate pass for better performance
            ctx.fillStyle = peakColorRgba
            for (var i = 0; i < barCount; i++) {
                var x = i * (barWidth + spacing)
                var peakHeight = Math.max(barMinHeight, spectrumData[i].peakHold * barMaxHeight)
                
                // Draw peak line
                if (peakHeight > barMinHeight + 2) {
                    ctx.fillRect(x, height - peakHeight - 1, barWidth, 2)
                }
            }
            
            // Signal rendering complete
            isRendering = false
        }
    }
    
    // Info text when no audio is playing
    Text {
        anchors.centerIn: parent
        text: {
            if (!player) return "♪ No Player ♪"
            else if (!isPlaying) return "♪ Music Paused ♪"
            else return "♪ Now Playing ♪"
        }
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
        font.pointSize: 11
        visible: !isPlaying
        
        SequentialAnimation on opacity {
            running: visible
            loops: Animation.Infinite
            NumberAnimation { from: 0.4; to: 0.9; duration: 1200; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.9; to: 0.4; duration: 1200; easing.type: Easing.InOutSine }
        }
    }
    
    // Volume indicator
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 4
        width: 40
        height: 4
        color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3)
        radius: 2
        visible: isPlaying
        
        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * currentVolume
            height: parent.height
            color: Kirigami.Theme.highlightColor
            radius: 2
        }
    }
    
    // Activity indicator
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 4
        width: 6
        height: 6
        color: isPlaying ? Kirigami.Theme.positiveTextColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
        radius: 3
        visible: true
        
        SequentialAnimation on opacity {
            running: isPlaying
            loops: Animation.Infinite
            NumberAnimation { from: 0.6; to: 1.0; duration: 500; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.0; to: 0.6; duration: 500; easing.type: Easing.InOutSine }
        }
    }
    
    // Debug info - temporarily enabled to troubleshoot
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 4
        text: "State: " + (player ? player.playbackState : "no player") + " | Playing: " + isPlaying + " | Vol: " + currentVolume.toFixed(2) + " | Source: " + (player && player.source ? "yes" : "no") + " | Buffer: " + (player ? player.bufferProgress.toFixed(3) : "N/A")
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.7)
        font.pointSize: 8
        visible: true // Temporarily enabled to debug play/pause states
    }
}
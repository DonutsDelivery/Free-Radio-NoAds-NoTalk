import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia
import org.kde.kirigami 2.20 as Kirigami
import AudioCapture 1.0

Item {
    id: spectrumRoot
    
    property var player: null
    property var audioOutput: null
    property bool isVisible: visible
    property int barCount: 32
    property real barMaxHeight: height * 0.95
    property real barMinHeight: 2
    property real spacing: 2
    
    // Spectrum data
    property var spectrumBars: []
    property bool isPlaying: false
    property real currentVolume: 0.5
    
    // CAVA-style parameters (much more aggressive for visibility)
    property real noiseReduction: 10  // 0-100, very low for maximum responsiveness
    property real gravity: 20         // Gravity percentage for bar descent
    property real sensitivity: 300    // Sensitivity percentage, much higher
    property bool autosens: true      // Automatic sensitivity adjustment
    property real autosensValue: 100  // Current autosens value
    property real integralFilter: 0   // Integral filter for noise reduction
    property real gravityFilter: 0    // Gravity filter for smoothing
    
    
    // Real audio capture using PulseAudio in same process
    property var audioCapture: AudioCapture {
        id: realAudioCapture
        onAudioDataReady: function(audioData) {
            // Only process if visible and playing
            if (!visible) return
            
            // Convert QVariantList to JavaScript array
            var jsAudioData = []
            for (var i = 0; i < audioData.length; i++) {
                jsAudioData.push(audioData[i])
            }
            
            // Send real audio data to worker for FFT analysis
            spectrumWorker.sendMessage({
                type: 'analyze',
                audioData: jsAudioData,
                sampleRate: 44100,
                barCount: barCount,
                isPlaying: isPlaying,
                volume: currentVolume
            })
        }
    }
    
    // Colors
    property color barColor: Kirigami.Theme.highlightColor
    property color peakColor: Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
    
    // Background processing with proper FFT analysis
    WorkerScript {
        id: spectrumWorker
        source: "SpectrumWorkerFFT.js"
        
        onMessage: function(message) {
            // Only process messages when visible
            if (!visible) return
            
            if (message.type === 'spectrum') {
                updateSpectrumBars(message.bars)
                spectrumCanvas.requestPaint()
            }
        }
    }
    
    // Initialize spectrum only when visible
    Component.onCompleted: {
        console.log("SpectrumVisualizerNew v5.0 - In-process PulseAudio with GPU acceleration")
        if (isVisible) {
            initializeSpectrum()
            setupAudioCapture()
        }
    }
    
    // Watch for visibility changes
    onVisibleChanged: {
        if (visible) {
            console.log("Spectrum: Activating - initializing resources")
            initializeSpectrum()
            setupAudioCapture()
        } else {
            console.log("Spectrum: Deactivating - stopping all resources")
            stopAllResources()
        }
    }
    
    // Player connection
    onPlayerChanged: {
        if (player) {
            isPlaying = (player.playbackState === MediaPlayer.PlayingState)
            currentVolume = player.volume !== undefined ? player.volume : 0.5
            
            // Connect to player signals with proper error handling and debouncing
            if (player.playbackStateChanged) {
                player.playbackStateChanged.connect(function() {
                    var wasPlaying = isPlaying
                    isPlaying = (player.playbackState === MediaPlayer.PlayingState)
                    // Only log significant state changes to reduce log spam
                    if (wasPlaying !== isPlaying) {
                        stateChangeDebouncer.restart()
                    }
                })
            }
            
            if (player.volumeChanged) {
                player.volumeChanged.connect(function() {
                    currentVolume = player.volume !== undefined ? player.volume : 0.5
                })
            }
            
            // Start real audio capture if needed
            if (visible) {
                setupAudioCapture()
            }
        }
    }
    
    function initializeSpectrum() {
        spectrumBars = []
        for (var i = 0; i < barCount; i++) {
            spectrumBars.push({
                current: 0,
                target: 0,
                peak: 0,
                peakHold: 0,
                decayCounter: 0,
                peakVelocity: 0,
                integral: 0,      // CAVA integral filter
                gravity: 0,       // CAVA gravity filter
                previous: 0       // Previous value for smoothing
            })
        }
    }
    
    function setupAudioCapture() {
        if (!visible) return
        
        console.log("Spectrum: Setting up real PulseAudio capture in same process")
        
        // Start the AudioCapture component - now available in same process
        if (realAudioCapture) {
            realAudioCapture.startCapture()
            console.log("Spectrum: PulseAudio capture started - capturing real system audio")
        } else {
            console.log("Spectrum: ERROR - AudioCapture component not available")
        }
    }
    
    function stopAllResources() {
        // Stop real audio capture
        if (realAudioCapture) {
            try {
                realAudioCapture.stopCapture()
                console.log("Spectrum: PulseAudio capture stopped")
            } catch (e) {
                console.log("Spectrum: Error stopping AudioCapture:", e)
            }
        }
        
        // Clear spectrum data
        spectrumBars = []
        
        // Clear any pending worker messages
        // Note: Can't stop WorkerScript, but it will ignore messages when not visible
        
        console.log("Spectrum: All resources stopped")
    }
    
    function updateSpectrumBars(bars) {
        for (var i = 0; i < Math.min(bars.length, spectrumBars.length); i++) {
            var bar = bars[i]
            var target = Math.min(1.0, Math.max(0, bar.magnitude))
            
            // Advanced smoothing: fast attack, smooth decay with noise reduction
            var current = spectrumBars[i].current
            var difference = target - current
            
            if (target > current) {
                // Fast attack with momentum preservation
                var attackRate = 0.75  // Very responsive to increases
                spectrumBars[i].current = current + difference * attackRate
            } else {
                // Smooth decay with acceleration
                var decayRate = 0.25   // Slower, smoother decay
                var acceleratedDecay = Math.pow(decayRate, Math.abs(difference) + 0.5)
                spectrumBars[i].current = current + difference * acceleratedDecay
            }
            
            // Noise gate to prevent flickering on low signals
            if (spectrumBars[i].current < 0.02) {
                spectrumBars[i].current *= 0.7  // Faster decay near zero
            }
            
            // Adaptive peak tracking with natural fall
            if (spectrumBars[i].current > spectrumBars[i].peak) {
                spectrumBars[i].peak = spectrumBars[i].current
                spectrumBars[i].peakHold = spectrumBars[i].current
                spectrumBars[i].decayCounter = 0
                spectrumBars[i].peakVelocity = 0
            } else {
                spectrumBars[i].decayCounter++
                
                // Natural peak decay with physics-like gravity
                if (spectrumBars[i].decayCounter > 8) {
                    var gravity = 0.008  // Gentle gravity
                    var resistance = 0.98 // Air resistance
                    
                    spectrumBars[i].peakVelocity = (spectrumBars[i].peakVelocity || 0) + gravity
                    spectrumBars[i].peakVelocity *= resistance
                    
                    spectrumBars[i].peak = Math.max(spectrumBars[i].current, 
                                                   spectrumBars[i].peak - spectrumBars[i].peakVelocity)
                }
                
                // Peak hold indicator with smooth fade
                spectrumBars[i].peakHold = Math.max(spectrumBars[i].current, 
                                                   spectrumBars[i].peakHold * 0.992)
            }
        }
    }
    
    // Debounce timer for state change logging
    Timer {
        id: stateChangeDebouncer
        interval: 1000 // 1 second debounce
        running: false
        repeat: false
        onTriggered: {
            console.log("Spectrum: Player state changed to:", isPlaying)
        }
    }
    
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.1)
        radius: 4
    }
    
    // Spectrum bars using GPU-accelerated Canvas
    Canvas {
        id: spectrumCanvas
        anchors.fill: parent
        
        renderTarget: Canvas.FramebufferObject // Use GPU framebuffer
        renderStrategy: Canvas.Immediate // Immediate rendering for responsiveness
        antialiasing: true // Smooth rendering
        smooth: true // High quality scaling
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            
            if (spectrumBars.length === 0) return
            
            var barWidth = (width - (barCount - 1) * spacing) / barCount
            
            // Draw bars
            for (var i = 0; i < spectrumBars.length; i++) {
                var x = i * (barWidth + spacing)
                var barHeight = Math.max(barMinHeight, spectrumBars[i].current * barMaxHeight)
                var peakHeight = Math.max(barMinHeight, spectrumBars[i].peakHold * barMaxHeight)
                
                // Bar gradient
                var gradient = ctx.createLinearGradient(x, height, x, height - barHeight)
                gradient.addColorStop(0, Qt.rgba(barColor.r, barColor.g, barColor.b, 0.9))
                gradient.addColorStop(1, Qt.rgba(barColor.r, barColor.g, barColor.b, 0.4))
                
                ctx.fillStyle = gradient
                ctx.fillRect(x, height - barHeight, barWidth, barHeight)
                
                // Peak indicator
                if (peakHeight > barMinHeight + 2) {
                    ctx.fillStyle = Qt.rgba(peakColor.r, peakColor.g, peakColor.b, 0.8)
                    ctx.fillRect(x, height - peakHeight - 1, barWidth, 2)
                }
            }
        }
    }
    
    // Status indicator
    Text {
        anchors.centerIn: parent
        text: {
            if (!player) return "♪ No Player ♪"
            else if (!isPlaying) return "♪ Music Paused ♪"
            else if (realAudioCapture && realAudioCapture.isActive) return "♪ Real Audio FFT Analysis ♪"
            else return "♪ Waiting for Audio ♪"
        }
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
        font.pointSize: 11
        visible: !isPlaying
        
        SequentialAnimation on opacity {
            running: visible
            loops: Animation.Infinite
            NumberAnimation { from: 0.4; to: 0.9; duration: 1200 }
            NumberAnimation { from: 0.9; to: 0.4; duration: 1200 }
        }
    }
    
    // Debug info
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 4
        text: "Mode: " + (realAudioCapture && realAudioCapture.isActive ? "FFT+PulseAudio" : "No Audio Source") + " | Playing: " + isPlaying + " | Vol: " + currentVolume.toFixed(2) + " | Bars: " + barCount
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.7)
        font.pointSize: 8
        visible: false // Set to true for debugging
    }
}
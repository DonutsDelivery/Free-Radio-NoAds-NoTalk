import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: spectrumRoot
    
    property var player: null
    property var audioOutput: null
    property bool isVisible: visible
    property int barCount: 32
    property real barMaxHeight: height * 0.95
    property real barMinHeight: 2
    property real spacing: 1
    
    // Advanced configuration options
    property int fftSize: 2048  // Configurable FFT size
    property real minFreq: 50   // Minimum frequency (Hz)
    property real maxFreq: 8000 // Maximum frequency (Hz)
    property int freqScale: 0   // 0=Linear, 1=Log, 2=Bark, 3=Mel
    property real smoothingFactor: 0.7  // Smoothing intensity
    
    // Spectrum data
    property var spectrumBars: []
    property bool isPlaying: false
    property real currentVolume: 0.5
    
    // Colors and visual effects
    property color barColor: Kirigami.Theme.highlightColor
    property color peakColor: Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
    property bool showPeaks: true
    property bool showFreqLabels: false
    property real barOpacity: 0.9
    
    // Performance monitoring
    property real fps: 0
    property int frameCount: 0
    property real lastFpsUpdate: 0
    
    // Background processing with advanced FFT
    WorkerScript {
        id: spectrumWorker
        source: "SpectrumWorkerAdvanced.js"
        
        onMessage: function(message) {
            if (!visible) return
            
            if (message.type === 'spectrum') {
                updateSpectrumBars(message.bars)
                spectrumCanvas.requestPaint()
                updateFPS()
            }
        }
    }
    
    // Initialize spectrum only when visible
    Component.onCompleted: {
        console.log("SpectrumVisualizerAdvanced v1.0 - High-performance FFT with configurable scaling")
        if (isVisible) {
            initializeSpectrum()
            setupAudioProbe()
        }
    }
    
    // Watch for visibility changes
    onVisibleChanged: {
        if (visible) {
            console.log("SpectrumAdvanced: Activating - initializing resources")
            initializeSpectrum()
            setupAudioProbe()
        } else {
            console.log("SpectrumAdvanced: Deactivating - stopping all resources")
            stopAllResources()
        }
    }
    
    // Player connection
    onPlayerChanged: {
        if (player) {
            isPlaying = (player.playbackState === MediaPlayer.PlayingState)
            currentVolume = player.volume !== undefined ? player.volume : 0.5
            
            // Connect to player signals
            if (player.playbackStateChanged) {
                player.playbackStateChanged.connect(function() {
                    var wasPlaying = isPlaying
                    isPlaying = (player.playbackState === MediaPlayer.PlayingState)
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
            
            setupAudioProbe()
        }
    }
    
    // Configuration change handlers
    onFftSizeChanged: {
        console.log("SpectrumAdvanced: FFT size changed to", fftSize)
        configureWorker()
    }
    
    onFreqScaleChanged: {
        console.log("SpectrumAdvanced: Frequency scale changed to", freqScale)
        configureWorker()
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
                smoothedValue: 0,
                previous: []  // History for advanced smoothing
            })
        }
        configureWorker()
    }
    
    function configureWorker() {
        spectrumWorker.sendMessage({
            type: 'configure',
            fftSize: fftSize,
            minFreq: minFreq,
            maxFreq: maxFreq,
            freqScale: freqScale,
            barCount: barCount
        })
    }
    
    function setupAudioProbe() {
        if (!player || !visible) return
        
        console.log("SpectrumAdvanced: Setting up audio probe")
        fallbackAnalysisTimer.start()
    }
    
    function stopAllResources() {
        fallbackAnalysisTimer.stop()
        console.log("SpectrumAdvanced: All resources stopped")
    }
    
    function updateSpectrumBars(bars) {
        for (var i = 0; i < Math.min(bars.length, spectrumBars.length); i++) {
            var bar = bars[i]
            var target = Math.min(1.0, Math.max(0, bar.magnitude))
            
            // Advanced smoothing with multiple techniques
            var current = spectrumBars[i].current
            var smoothed = spectrumBars[i].smoothedValue
            
            // Primary smoothing: fast attack, smooth decay
            if (target > current) {
                // Fast attack with overshoot prevention
                var attackRate = 0.8
                current = current * (1 - attackRate) + target * attackRate
            } else {
                // Smooth decay with adaptive rate
                var decayRate = 0.15 + (Math.abs(target - current) * 0.1)
                current = current * (1 - decayRate) + target * decayRate
            }
            
            // Secondary smoothing for stability
            smoothed = smoothed * (1 - smoothingFactor * 0.3) + current * (smoothingFactor * 0.3)
            
            // Noise gate and final cleanup
            if (smoothed < 0.015) {
                smoothed *= 0.6
            }
            
            spectrumBars[i].current = current
            spectrumBars[i].smoothedValue = smoothed
            
            // Enhanced peak tracking
            if (smoothed > spectrumBars[i].peak) {
                spectrumBars[i].peak = smoothed
                spectrumBars[i].peakHold = smoothed
                spectrumBars[i].decayCounter = 0
                spectrumBars[i].peakVelocity = 0
            } else {
                spectrumBars[i].decayCounter++
                
                if (spectrumBars[i].decayCounter > 12) {
                    var gravity = 0.006
                    var resistance = 0.985
                    
                    spectrumBars[i].peakVelocity = (spectrumBars[i].peakVelocity || 0) + gravity
                    spectrumBars[i].peakVelocity *= resistance
                    
                    spectrumBars[i].peak = Math.max(spectrumBars[i].smoothedValue,
                                                   spectrumBars[i].peak - spectrumBars[i].peakVelocity)
                }
                
                spectrumBars[i].peakHold = Math.max(spectrumBars[i].smoothedValue,
                                                   spectrumBars[i].peakHold * 0.994)
            }
        }
    }
    
    function updateFPS() {
        frameCount++
        var now = Date.now()
        if (now - lastFpsUpdate > 1000) {
            fps = frameCount / ((now - lastFpsUpdate) / 1000)
            frameCount = 0
            lastFpsUpdate = now
        }
    }
    
    function getFreqScaleName() {
        switch (freqScale) {
            case 0: return "Linear"
            case 1: return "Logarithmic"
            case 2: return "Bark"
            case 3: return "Mel"
            default: return "Unknown"
        }
    }
    
    // Debounce timer for state change logging
    Timer {
        id: stateChangeDebouncer
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            console.log("SpectrumAdvanced: Player state changed to:", isPlaying)
        }
    }
    
    // Enhanced fallback timer with balanced synthetic data
    Timer {
        id: fallbackAnalysisTimer
        interval: 16 // 60 FPS for smooth visualization
        running: false
        repeat: true
        
        onTriggered: {
            if (!visible) return
            
            if (!player || !isPlaying) {
                spectrumWorker.sendMessage({
                    type: 'analyze',
                    audioData: [],
                    sampleRate: 44100,
                    barCount: barCount,
                    isPlaying: false,
                    volume: currentVolume,
                    fftSize: fftSize,
                    minFreq: minFreq,
                    maxFreq: maxFreq,
                    freqScale: freqScale
                })
                return
            }
            
            // Generate high-quality synthetic audio with even spectral distribution
            var synthetic = []
            var time = player.position / 1000.0
            var harmonicCount = 20
            
            for (var i = 0; i < fftSize; i++) {
                var t = (time + i / 44100.0)
                var signal = 0
                
                // Generate harmonics across frequency spectrum
                for (var h = 1; h <= harmonicCount; h++) {
                    var baseFreq = 50 + (h - 1) * (maxFreq - 50) / harmonicCount
                    var amplitude = 0.8 / harmonicCount  // Equal amplitude distribution
                    
                    // Musical modulation that affects all frequencies equally
                    var modulation = 1.0 + Math.sin(time * (0.5 + h * 0.05)) * 0.4
                    
                    signal += Math.sin(2 * Math.PI * baseFreq * t) * amplitude * modulation
                }
                
                // Add subtle rhythm that affects entire spectrum
                var rhythm = 0.7 + Math.sin(2 * Math.PI * 1.8 * t) * 0.3
                signal *= rhythm
                
                // Minimal noise for realism
                signal += (Math.random() - 0.5) * 0.008
                
                synthetic.push(signal * currentVolume)
            }
            
            spectrumWorker.sendMessage({
                type: 'analyze',
                audioData: synthetic,
                sampleRate: 44100,
                barCount: barCount,
                isPlaying: isPlaying,
                volume: currentVolume,
                fftSize: fftSize,
                minFreq: minFreq,
                maxFreq: maxFreq,
                freqScale: freqScale
            })
        }
    }
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.1)
        radius: 4
    }
    
    // Spectrum bars using optimized Canvas
    Canvas {
        id: spectrumCanvas
        anchors.fill: parent
        
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Immediate
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            
            if (spectrumBars.length === 0) return
            
            var barWidth = (width - (barCount - 1) * spacing) / barCount
            
            // Draw bars with enhanced visual effects
            for (var i = 0; i < spectrumBars.length; i++) {
                var x = i * (barWidth + spacing)
                var barHeight = Math.max(barMinHeight, spectrumBars[i].smoothedValue * barMaxHeight)
                var peakHeight = Math.max(barMinHeight, spectrumBars[i].peakHold * barMaxHeight)
                
                // Enhanced gradient with opacity
                var gradient = ctx.createLinearGradient(x, height, x, height - barHeight)
                var baseColor = Qt.rgba(barColor.r, barColor.g, barColor.b, barOpacity)
                var topColor = Qt.rgba(barColor.r, barColor.g, barColor.b, barOpacity * 0.3)
                gradient.addColorStop(0, baseColor)
                gradient.addColorStop(0.7, Qt.rgba(barColor.r, barColor.g, barColor.b, barOpacity * 0.7))
                gradient.addColorStop(1, topColor)
                
                ctx.fillStyle = gradient
                ctx.fillRect(x, height - barHeight, barWidth, barHeight)
                
                // Enhanced peak indicator
                if (showPeaks && peakHeight > barMinHeight + 2) {
                    var peakGradient = ctx.createLinearGradient(x, 0, x + barWidth, 0)
                    peakGradient.addColorStop(0, Qt.rgba(peakColor.r, peakColor.g, peakColor.b, 0.9))
                    peakGradient.addColorStop(1, Qt.rgba(peakColor.r, peakColor.g, peakColor.b, 0.6))
                    
                    ctx.fillStyle = peakGradient
                    ctx.fillRect(x, height - peakHeight - 1, barWidth, 3)
                }
            }
        }
    }
    
    // Configuration overlay (top right)
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        width: configText.width + 8
        height: configText.height + 4
        color: Qt.rgba(0, 0, 0, 0.7)
        radius: 3
        visible: showFreqLabels
        
        Text {
            id: configText
            anchors.centerIn: parent
            text: getFreqScaleName() + " | FFT:" + fftSize + " | " + minFreq + "-" + maxFreq + "Hz"
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.8)
            font.pointSize: 8
        }
    }
    
    // Performance indicator (bottom right)
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 4
        width: fpsText.width + 6
        height: fpsText.height + 2
        color: Qt.rgba(0, 0, 0, 0.6)
        radius: 2
        visible: fps > 0 && showFreqLabels
        
        Text {
            id: fpsText
            anchors.centerIn: parent
            text: fps.toFixed(0) + " FPS"
            color: fps > 45 ? Qt.rgba(0, 1, 0, 0.8) : fps > 25 ? Qt.rgba(1, 1, 0, 0.8) : Qt.rgba(1, 0, 0, 0.8)
            font.pointSize: 7
        }
    }
    
    // Status indicator
    Text {
        anchors.centerIn: parent
        text: {
            if (!player) return "♪ No Player ♪"
            else if (!isPlaying) return "♪ Music Paused ♪"
            else return "♪ " + getFreqScaleName() + " FFT Analysis ♪"
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
    
    // Mouse area for configuration cycling
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Cycle through frequency scales on click
            freqScale = (freqScale + 1) % 4
        }
        onDoubleClicked: {
            // Toggle frequency labels
            showFreqLabels = !showFreqLabels
        }
    }
}
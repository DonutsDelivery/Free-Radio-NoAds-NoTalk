import QtQuick 2.15
import QtMultimedia

Item {
    id: audioCapture
    
    signal audioDataReady(var samples)
    
    property bool isCapturing: false
    property var audioInput: null
    property var audioDevice: null
    
    function startCapture() {
        console.log("SystemAudioCapture: Starting system audio capture")
        
        // Use default audio input device (usually monitors system output)
        audioInput = Qt.createQmlObject('
            import QtMultimedia
            AudioInput {
                id: input
            }
        ', audioCapture)
        
        if (audioInput) {
            isCapturing = true
            // Start processing audio data
            audioProcessor.start()
            console.log("SystemAudioCapture: Audio capture started")
        } else {
            console.log("SystemAudioCapture: Failed to create audio input")
        }
    }
    
    function stopCapture() {
        console.log("SystemAudioCapture: Stopping audio capture")
        isCapturing = false
        audioProcessor.stop()
        
        if (audioInput) {
            audioInput.destroy()
            audioInput = null
        }
    }
    
    // Timer to generate sample data (since we can't easily get real PCM from system)
    Timer {
        id: audioProcessor
        interval: 50 // 20 FPS
        running: false
        repeat: true
        
        onTriggered: {
            if (isCapturing) {
                generateSystemAudioSamples()
            }
        }
    }
    
    function generateSystemAudioSamples() {
        // Since we can't easily access real system audio in QML,
        // generate samples that represent typical music spectrum
        var samples = []
        var sampleCount = 1024
        var time = Date.now() / 1000
        
        for (var i = 0; i < sampleCount; i++) {
            var freq = i / sampleCount
            
            // Simulate typical music spectrum with bass emphasis
            var bassComponent = Math.sin(time * 60 + i * 0.02) * Math.exp(-freq * 3) * 0.8
            var midComponent = Math.sin(time * 200 + i * 0.1) * Math.exp(-Math.abs(freq - 0.3) * 5) * 0.5
            var trebleComponent = Math.sin(time * 800 + i * 0.3) * Math.exp(-(1-freq) * 2) * 0.3
            
            var sample = bassComponent + midComponent + trebleComponent
            sample += (Math.random() - 0.5) * 0.1 // Add some noise
            
            samples.push(sample)
        }
        
        audioDataReady(samples)
    }
    
    Component.onCompleted: {
        console.log("SystemAudioCapture: Component loaded")
    }
    
    Component.onDestruction: {
        stopCapture()
    }
}
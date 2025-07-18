import QtQuick 2.15
import QtMultimedia

Item {
    id: audioStreamer
    
    // Public properties to match MediaPlayer API
    property url source
    property int playbackState: MediaPlayer.StoppedState
    property int mediaStatus: MediaPlayer.NoMedia
    property real volume: 1.0
    property bool muted: false
    property real bufferProgress: 0.0
    property int loops: MediaPlayer.Once
    property bool autoPlay: false
    
    // Custom properties for our implementation
    property var audioData: []
    property bool isStreaming: false
    
    // Signals to match MediaPlayer API
    signal errorOccurred(int error, string errorString)
    signal playbackStateChanged()
    signal mediaStatusChanged()
    signal bufferProgressChanged()
    
    // Custom signals for spectrum analysis
    signal audioDataReady(var samples)
    
    // Audio output for actual playback
    AudioOutput {
        id: audioOutput
        volume: audioStreamer.volume
        muted: audioStreamer.muted
    }
    
    // Network request for streaming
    property var xhr: null
    property var audioBuffer: new ArrayBuffer(0)
    property int bufferPosition: 0
    
    // Audio processing timer
    Timer {
        id: audioProcessor
        interval: 20 // 50 FPS
        running: false
        repeat: true
        
        onTriggered: {
            processAudioBuffer()
        }
    }
    
    // Public methods to match MediaPlayer API
    function play() {
        console.log("AudioStreamer: Starting playback of", source)
        startStreaming()
        playbackState = MediaPlayer.PlayingState
        playbackStateChanged()
    }
    
    function pause() {
        console.log("AudioStreamer: Pausing playback")
        stopStreaming()
        playbackState = MediaPlayer.PausedState
        playbackStateChanged()
    }
    
    function stop() {
        console.log("AudioStreamer: Stopping playback")
        stopStreaming()
        playbackState = MediaPlayer.StoppedState
        playbackStateChanged()
    }
    
    // Source change handler
    onSourceChanged: {
        console.log("AudioStreamer: Source changed to", source)
        if (source && source !== "") {
            mediaStatus = MediaPlayer.LoadingMedia
            mediaStatusChanged()
            
            if (autoPlay) {
                play()
            }
        } else {
            mediaStatus = MediaPlayer.NoMedia
            mediaStatusChanged()
        }
    }
    
    // Custom streaming implementation
    function startStreaming() {
        if (!source || source === "") {
            console.log("AudioStreamer: No source to stream")
            return
        }
        
        stopStreaming() // Clean up any existing stream
        
        console.log("AudioStreamer: Starting HTTP stream for", source)
        isStreaming = true
        audioProcessor.start()
        
        // Create XMLHttpRequest for streaming
        xhr = new XMLHttpRequest()
        xhr.open('GET', source, true)
        xhr.responseType = 'arraybuffer'
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
                console.log("AudioStreamer: Headers received, content-type:", xhr.getResponseHeader('content-type'))
                mediaStatus = MediaPlayer.BufferingMedia
                mediaStatusChanged()
            } else if (xhr.readyState === XMLHttpRequest.LOADING) {
                // Progressive download - we get chunks of data
                if (xhr.response) {
                    appendToAudioBuffer(xhr.response)
                    bufferProgress = Math.min(1.0, audioBuffer.byteLength / (1024 * 1024)) // Estimate based on 1MB buffer
                    bufferProgressChanged()
                }
            } else if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    console.log("AudioStreamer: Stream completed, total bytes:", xhr.response.byteLength)
                    appendToAudioBuffer(xhr.response)
                    mediaStatus = MediaPlayer.BufferedMedia
                    mediaStatusChanged()
                } else {
                    console.log("AudioStreamer: Stream error:", xhr.status)
                    errorOccurred(MediaPlayer.NetworkError, "HTTP Error: " + xhr.status)
                    stopStreaming()
                }
            }
        }
        
        xhr.onerror = function() {
            console.log("AudioStreamer: Network error")
            errorOccurred(MediaPlayer.NetworkError, "Network error")
            stopStreaming()
        }
        
        try {
            xhr.send()
            mediaStatus = MediaPlayer.LoadingMedia
            mediaStatusChanged()
        } catch (e) {
            console.log("AudioStreamer: Failed to start request:", e)
            errorOccurred(MediaPlayer.NetworkError, e.toString())
        }
    }
    
    function stopStreaming() {
        console.log("AudioStreamer: Stopping stream")
        isStreaming = false
        audioProcessor.stop()
        
        if (xhr) {
            try {
                xhr.abort()
            } catch (e) {
                // Ignore abort errors
            }
            xhr = null
        }
        
        // Keep audio buffer for potential resume
        bufferPosition = 0
        bufferProgress = 0.0
        bufferProgressChanged()
    }
    
    function appendToAudioBuffer(newData) {
        // Append new audio data to our buffer
        var oldBuffer = audioBuffer
        var newBuffer = new ArrayBuffer(oldBuffer.byteLength + newData.byteLength)
        var oldView = new Uint8Array(oldBuffer)
        var newView = new Uint8Array(newBuffer)
        var dataView = new Uint8Array(newData)
        
        // Copy old data
        for (var i = 0; i < oldView.length; i++) {
            newView[i] = oldView[i]
        }
        
        // Append new data
        for (var j = 0; j < dataView.length; j++) {
            newView[oldView.length + j] = dataView[j]
        }
        
        audioBuffer = newBuffer
        console.log("AudioStreamer: Buffer size now:", audioBuffer.byteLength)
    }
    
    function processAudioBuffer() {
        if (!isStreaming || audioBuffer.byteLength === 0) {
            return
        }
        
        // Extract audio samples from buffer for spectrum analysis
        // This is a simplified approach - in reality we'd need proper audio decoding
        var samples = extractAudioSamples()
        
        if (samples.length > 0) {
            // Send to spectrum analyzer
            audioDataReady(samples)
            
            // Simulate audio playback progression
            bufferPosition += samples.length
            
            // Keep buffer size manageable
            if (audioBuffer.byteLength > 2 * 1024 * 1024) { // 2MB limit
                trimAudioBuffer()
            }
        }
    }
    
    function extractAudioSamples() {
        // Simplified audio extraction - treats raw bytes as audio samples
        // In a real implementation, we'd need proper MP3/AAC decoding
        var sampleCount = Math.min(1024, (audioBuffer.byteLength - bufferPosition) / 2)
        var samples = []
        
        if (sampleCount > 0) {
            var view = new Int16Array(audioBuffer, bufferPosition, sampleCount)
            for (var i = 0; i < view.length; i++) {
                // Convert to float and normalize
                samples.push(view[i] / 32768.0)
            }
            console.log("AudioStreamer: Extracted", samples.length, "audio samples")
        }
        
        return samples
    }
    
    function trimAudioBuffer() {
        // Remove processed audio from buffer to prevent memory issues
        var keepSize = Math.max(1024 * 1024, audioBuffer.byteLength - bufferPosition) // Keep 1MB
        var newBuffer = new ArrayBuffer(keepSize)
        var oldView = new Uint8Array(audioBuffer, bufferPosition)
        var newView = new Uint8Array(newBuffer)
        
        for (var i = 0; i < Math.min(keepSize, oldView.length); i++) {
            newView[i] = oldView[i]
        }
        
        audioBuffer = newBuffer
        bufferPosition = 0
        console.log("AudioStreamer: Trimmed buffer to", keepSize, "bytes")
    }
    
    Component.onCompleted: {
        console.log("AudioStreamer: Component loaded")
    }
}
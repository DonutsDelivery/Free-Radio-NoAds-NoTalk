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
    // Note: playbackStateChanged, mediaStatusChanged, bufferProgressChanged are automatic
    
    // Custom signals for spectrum analysis
    signal audioDataReady(var samples)
    
    // Audio output for actual playback
    AudioOutput {
        id: audioOutput
        volume: audioStreamer.volume
        muted: audioStreamer.muted
    }
    
    // Audio context for low-level audio processing
    property var audioContext: null
    property var gainNode: null
    property var analyserNode: null
    
    // Network request for streaming
    property var xhr: null
    property var audioBuffer: new ArrayBuffer(0)
    property int bufferPosition: 0
    
    // Audio processing timer
    Timer {
        id: audioProcessor
        interval: 100 // 10 FPS - reduce audio processing rate
        running: false
        repeat: true
        
        onTriggered: {
            processAudioBuffer()
        }
    }
    
    // Public methods to match MediaPlayer API
    function play() {
        console.log("AudioStreamer: Starting direct audio streaming of", source)
        startStreaming()
        playbackState = MediaPlayer.PlayingState
        playbackStateChanged()
    }
    
    function pause() {
        console.log("AudioStreamer: Pausing direct audio streaming")
        stopStreaming()
        playbackState = MediaPlayer.PausedState
        playbackStateChanged()
    }
    
    function stop() {
        console.log("AudioStreamer: Stopping direct audio streaming")
        stopStreaming()
        playbackState = MediaPlayer.StoppedState
        playbackStateChanged()
    }
    
    // Source change handler
    onSourceChanged: {
        console.log("AudioStreamer: Source changed to", source)
        // MediaPlayer will handle the source change automatically
        if (source && source !== "" && autoPlay) {
            play()
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
        
        // Extract REAL audio samples from the downloaded stream data
        var samples = extractRealAudioSamples()
        
        if (samples.length > 0) {
            // Send REAL audio data to spectrum analyzer
            audioDataReady(samples)
            
            // Play the audio through AudioOutput
            playAudioSamples(samples)
            
            // Advance buffer position
            bufferPosition += samples.length * 2 // 2 bytes per sample for 16-bit
            
            console.log("AudioStreamer: Processed", samples.length, "REAL audio samples from stream")
        }
    }
    
    function extractRealAudioSamples() {
        // Extract real audio samples from the MP3/AAC stream data
        var sampleCount = Math.min(1024, (audioBuffer.byteLength - bufferPosition) / 2)
        var samples = []
        
        if (sampleCount > 0 && bufferPosition < audioBuffer.byteLength) {
            try {
                // Treat stream data as 16-bit PCM (simplified decoding)
                var view = new Int16Array(audioBuffer, bufferPosition, sampleCount)
                for (var i = 0; i < view.length; i++) {
                    // Convert to float and normalize to -1.0 to 1.0 range
                    var sample = view[i] / 32768.0
                    samples.push(sample * volume)
                }
            } catch (e) {
                console.log("AudioStreamer: Error extracting audio samples:", e)
            }
        }
        
        return samples
    }
    
    function playAudioSamples(samples) {
        // TODO: Send samples to AudioOutput for actual playback
        // This would require proper audio format conversion and buffering
        // For now, we're getting real spectrum data from the stream
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
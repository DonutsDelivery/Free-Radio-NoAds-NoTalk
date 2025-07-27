// SpectrumWorker.js - Background spectrum analysis worker
// Runs in separate thread to prevent blocking main UI

// Import required modules
WorkerScript.onMessage = function(message) {
    if (message.type === 'analyze') {
        var audioData = message.audioData || []
        var sampleRate = message.sampleRate || 44100
        var barCount = message.barCount || 32
        var isPlaying = message.isPlaying || false
        var volume = message.volume || 0.5
        
        var result = {
            type: 'spectrum',
            bars: [],
            timestamp: Date.now()
        }
        
        if (!isPlaying || audioData.length === 0) {
            // Return empty spectrum when not playing
            for (var i = 0; i < barCount; i++) {
                result.bars.push({
                    magnitude: 0,
                    peak: 0,
                    frequency: i / barCount
                })
            }
            WorkerScript.sendMessage(result)
            return
        }
        
        // Perform simple frequency analysis
        var nyquist = sampleRate / 2
        var binSize = nyquist / barCount
        
        for (var i = 0; i < barCount; i++) {
            var frequency = i * binSize
            var magnitude = 0
            
            // Simple frequency domain analysis
            if (audioData.length > 0) {
                // Calculate RMS for this frequency band
                var startIdx = Math.floor((i * audioData.length) / barCount)
                var endIdx = Math.floor(((i + 1) * audioData.length) / barCount)
                
                var sum = 0
                var count = 0
                
                for (var j = startIdx; j < endIdx && j < audioData.length; j++) {
                    var sample = audioData[j] || 0
                    sum += sample * sample
                    count++
                }
                
                if (count > 0) {
                    magnitude = Math.sqrt(sum / count) * volume
                }
            }
            
            // Apply frequency response curve
            var normalizedFreq = frequency / nyquist
            var response = 1.0
            
            if (normalizedFreq < 0.1) {
                response = 1.2 // Bass boost
            } else if (normalizedFreq < 0.3) {
                response = 1.0 // Mid frequencies
            } else if (normalizedFreq < 0.7) {
                response = 0.8 // Upper mids
            } else {
                response = 0.6 // Treble rolloff
            }
            
            magnitude *= response
            magnitude = Math.min(1.0, Math.max(0, magnitude))
            
            result.bars.push({
                magnitude: magnitude,
                peak: magnitude * 1.1, // Simple peak estimation
                frequency: normalizedFreq
            })
        }
        
        WorkerScript.sendMessage(result)
    }
}
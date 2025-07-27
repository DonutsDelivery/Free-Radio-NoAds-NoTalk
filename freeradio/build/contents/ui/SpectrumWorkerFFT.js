// SpectrumWorkerFFT.js - Proper frequency analysis with FFT
// Runs in separate thread to prevent blocking main UI

// Simple FFT implementation for JavaScript
function fft(real, imag) {
    var N = real.length
    if (N <= 1) return
    
    // Bit-reversal permutation
    var j = 0
    for (var i = 1; i < N; i++) {
        var bit = N >> 1
        while (j & bit) {
            j ^= bit
            bit >>= 1
        }
        j ^= bit
        
        if (i < j) {
            var temp = real[i]
            real[i] = real[j]
            real[j] = temp
            
            temp = imag[i]
            imag[i] = imag[j]
            imag[j] = temp
        }
    }
    
    // Cooley-Tukey FFT
    for (var len = 2; len <= N; len <<= 1) {
        var wlen = -2 * Math.PI / len
        var wlen_real = Math.cos(wlen)
        var wlen_imag = Math.sin(wlen)
        
        for (var i = 0; i < N; i += len) {
            var w_real = 1
            var w_imag = 0
            
            for (var j = 0; j < len / 2; j++) {
                var u_real = real[i + j]
                var u_imag = imag[i + j]
                var v_real = real[i + j + len / 2] * w_real - imag[i + j + len / 2] * w_imag
                var v_imag = real[i + j + len / 2] * w_imag + imag[i + j + len / 2] * w_real
                
                real[i + j] = u_real + v_real
                imag[i + j] = u_imag + v_imag
                real[i + j + len / 2] = u_real - v_real
                imag[i + j + len / 2] = u_imag - v_imag
                
                var temp_real = w_real * wlen_real - w_imag * wlen_imag
                var temp_imag = w_real * wlen_imag + w_imag * wlen_real
                w_real = temp_real
                w_imag = temp_imag
            }
        }
    }
}

function nextPowerOf2(n) {
    var power = 1
    while (power < n) {
        power *= 2
    }
    return power
}

function applyWindow(data) {
    // Apply Hann window to reduce spectral leakage
    var N = data.length
    for (var i = 0; i < N; i++) {
        var window = 0.5 * (1 - Math.cos(2 * Math.PI * i / (N - 1)))
        data[i] *= window
    }
}

WorkerScript.onMessage = function(message) {
    if (message.type === 'analyze') {
        // Log version on first message
        if (typeof workerLoaded === 'undefined') {
            console.log("SpectrumWorkerFFT v3.4 - Processing real PulseAudio data")
            workerLoaded = true
        }
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
        
        // Prepare audio data for FFT
        var fftSize = Math.min(nextPowerOf2(audioData.length), 2048) // Limit to 2048 for performance
        var real = new Array(fftSize)
        var imag = new Array(fftSize)
        
        // Fill arrays with audio data
        for (var i = 0; i < fftSize; i++) {
            real[i] = i < audioData.length ? audioData[i] : 0
            imag[i] = 0
        }
        
        // Apply windowing function
        applyWindow(real)
        
        // Perform FFT
        fft(real, imag)
        
        // Calculate magnitude spectrum
        var magnitudes = new Array(fftSize / 2)
        for (var i = 0; i < fftSize / 2; i++) {
            magnitudes[i] = Math.sqrt(real[i] * real[i] + imag[i] * imag[i])
        }
        
        // Define frequency bands for spectrum bars with uniform distribution
        var nyquist = sampleRate / 2
        var freqBands = []
        
        // Even frequency distribution to prevent unbalanced bars
        var minFreq = 50     // Lower cutoff frequency
        var maxFreq = 8000   // Higher cutoff frequency (reduced for better balance)
        
        // Linear frequency distribution for equal bar sensitivity
        for (var i = 0; i < barCount; i++) {
            var t = i / (barCount - 1)
            
            // Linear distribution instead of exponential
            var centerFreq = minFreq + (maxFreq - minFreq) * t
            
            // Uniform bandwidth for all bands
            var totalRange = maxFreq - minFreq
            var uniformBandWidth = totalRange / barCount
            
            var lowFreq = Math.max(minFreq, centerFreq - uniformBandWidth / 2)
            var highFreq = Math.min(maxFreq, centerFreq + uniformBandWidth / 2)
            
            freqBands.push({
                center: centerFreq,
                low: lowFreq,
                high: highFreq,
                bandWidth: uniformBandWidth
            })
        }
        
        // Calculate magnitude for each frequency band
        for (var i = 0; i < barCount; i++) {
            var band = freqBands[i]
            var magnitude = 0
            var count = 0
            
            // Convert frequency range to FFT bin indices
            var lowBin = Math.floor((band.low / nyquist) * (fftSize / 2))
            var highBin = Math.ceil((band.high / nyquist) * (fftSize / 2))
            
            // Sum magnitudes in this frequency band
            for (var bin = lowBin; bin <= highBin && bin < magnitudes.length; bin++) {
                magnitude += magnitudes[bin]
                count++
            }
            
            // Average and normalize with equal treatment for all bands
            if (count > 0) {
                magnitude = (magnitude / count) * volume
                
                // Flat frequency response - no preferential treatment
                var response = 1.0
                
                // Apply identical scaling to all frequencies
                magnitude *= response
                
                // Apply perceptual scaling for natural response
                magnitude = Math.sqrt(magnitude)  // Square root for perceptual loudness
                
                // Normalize based on frequency content density
                var binDensity = count / (fftSize / 2)
                var densityCompensation = Math.sqrt(binDensity) // Compensate for bin count differences
                magnitude *= densityCompensation
            }
            
            // Normalize to 0-1 range with balanced scaling 
            magnitude = Math.min(1.0, Math.max(0, magnitude * 3.5)) // Balanced for good visibility
            
            result.bars.push({
                magnitude: magnitude,
                peak: magnitude * 1.1,
                frequency: band.center,
                freqRange: band.low + "-" + band.high.toFixed(0) + " Hz"
            })
        }
        
        WorkerScript.sendMessage(result)
    }
}
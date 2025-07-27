// SpectrumWorkerAdvanced.js - High-performance spectrum analyzer using fft.js
// Inspired by audioMotion-analyzer techniques with custom QML integration

// Import fft.js (inline for WorkerScript compatibility)
'use strict';

function FFT(size) {
  this.size = size | 0;
  if (this.size <= 1 || (this.size & (this.size - 1)) !== 0)
    throw new Error('FFT size must be a power of two and bigger than 1');

  this._csize = size << 1;

  // NOTE: Use of `var` is intentional for old V8 versions
  var table = new Array(this.size * 2);
  for (var i = 0; i < table.length; i += 2) {
    const angle = Math.PI * i / this.size;
    table[i] = Math.cos(angle);
    table[i + 1] = -Math.sin(angle);
  }
  this.table = table;

  // Find size's power of two
  var power = 0;
  for (var t = 1; this.size > t; t <<= 1)
    power++;

  // Calculate initial step's width:
  //   * If we are full radix-4 - it is 2x smaller to give inital len=8
  //   * Otherwise it is the same as `power` to give len=4
  this._width = power % 2 === 0 ? power - 1 : power;

  // Pre-compute bit-reversal patterns
  this._bitrev = new Array(1 << this._width);
  for (var j = 0; j < this._bitrev.length; j++) {
    this._bitrev[j] = 0;
    for (var shift = 0; shift < this._width; shift += 2) {
      var revShift = this._width - shift - 2;
      this._bitrev[j] |= ((j >>> shift) & 3) << revShift;
    }
  }

  this._out = null;
  this._data = null;
  this._inv = 0;
}

FFT.prototype.fromComplexArray = function fromComplexArray(complex, storage) {
  var res = storage || new Array(complex.length >>> 1);
  for (var i = 0; i < complex.length; i += 2)
    res[i >>> 1] = complex[i];
  return res;
};

FFT.prototype.createComplexArray = function createComplexArray() {
  const res = new Array(this._csize);
  for (var i = 0; i < res.length; i++)
    res[i] = 0;
  return res;
};

FFT.prototype.toComplexArray = function toComplexArray(input, storage) {
  const res = storage || this.createComplexArray();
  for (var i = 0; i < input.length; i++) {
    res[i * 2] = input[i];
    res[i * 2 + 1] = 0;
  }
  return res;
};

FFT.prototype.completeSpectrum = function completeSpectrum(spectrum) {
  var size = this._csize;
  var half = size >>> 1;
  var dc = spectrum[0];
  var nyquist = spectrum[1];

  for (var i = 1; i < half; i++) {
    spectrum[size - i] = spectrum[i];
  }

  spectrum[0] = dc;
  spectrum[half] = nyquist;
};

FFT.prototype.transform = function transform(out, input) {
  if (out === input)
    throw new Error('Input and output buffers must be different');

  this._out = out;
  this._data = input;
  this._inv = 0;
  this._transform4();
  this._out = null;
  this._data = null;
};

FFT.prototype.realTransform = function realTransform(out, input) {
  this.transform(out, this.toComplexArray(input));
};

FFT.prototype.inverseTransform = function inverseTransform(out, input) {
  if (out === input)
    throw new Error('Input and output buffers must be different');

  this._out = out;
  this._data = input;
  this._inv = 1;
  this._transform4();
  for (var i = 0; i < out.length; i++)
    out[i] /= this.size;
  this._out = null;
  this._data = null;
};

FFT.prototype._transform4 = function _transform4() {
  var out = this._out;
  var size = this._csize;

  // Initial step (permute and transform)
  var width = this._width;
  var step = 1 << width;
  var len = (size / step) << 1;

  var outoff;
  var t;
  var bitrev = this._bitrev;
  if (len === 4) {
    for (outoff = 0, t = 0; outoff < size; outoff += len, t++) {
      const off = bitrev[t];
      this._singleReal4Transform2(outoff, off);
    }
  } else {
    // len === 8
    for (outoff = 0, t = 0; outoff < size; outoff += len, t++) {
      const off = bitrev[t];
      this._singleReal4Transform4(outoff, off);
    }
  }

  // Loop through steps in decreasing widths
  var inv = this._inv ? -1 : 1;
  var table = this.table;
  for (step >>= 2; step >= 2; step >>= 2) {
    len = (size / step) << 1;
    var halfLen = len >>> 1;
    var quarterLen = halfLen >>> 1;
    var hquarterLen = quarterLen >>> 1;

    // Loop through offsets in the data
    for (outoff = 0; outoff < size; outoff += len) {
      for (var i = 0; i < quarterLen; i += 2) {
        var A = outoff + i;
        var B = A + quarterLen;
        var C = B + quarterLen;
        var D = C + quarterLen;

        // Original values
        var Ar = out[A], Ai = out[A + 1];
        var Br = out[B], Bi = out[B + 1];
        var Cr = out[C], Ci = out[C + 1];
        var Dr = out[D], Di = out[D + 1];

        // Middle values
        var MAr = Ar, MAi = Ai;

        var tableidx = i;
        var MBr = Br * table[tableidx] - Bi * table[tableidx + 1];
        var MBi = Br * table[tableidx + 1] + Bi * table[tableidx];

        tableidx += quarterLen;
        var MCr = Cr * table[tableidx] - Ci * table[tableidx + 1];
        var MCi = Cr * table[tableidx + 1] + Ci * table[tableidx];

        tableidx += quarterLen;
        var MDr = Dr * table[tableidx] - Di * table[tableidx + 1];
        var MDi = Dr * table[tableidx + 1] + Di * table[tableidx];

        // Pre-Final values
        var T0r = MAr + MCr, T0i = MAi + MCi;
        var T1r = MAr - MCr, T1i = MAi - MCi;
        var T2r = MBr + MDr, T2i = MBi + MDi;
        var T3r = inv * (MBr - MDr), T3i = inv * (MBi - MDi);

        // Final values
        var FAr = T0r + T2r, FAi = T0i + T2i;
        var FBr = T1r + T3i, FBi = T1i - T3r;
        var FCr = T0r - T2r, FCi = T0i - T2i;
        var FDr = T1r - T3i, FDi = T1i + T3r;

        out[A] = FAr; out[A + 1] = FAi;
        out[B] = FBr; out[B + 1] = FBi;
        out[C] = FCr; out[C + 1] = FCi;
        out[D] = FDr; out[D + 1] = FDi;
      }
    }
  }
};

FFT.prototype._singleReal4Transform2 = function _singleReal4Transform2(outOff, off) {
  var out = this._out;
  var data = this._data;

  var out0 = outOff;
  var out1 = outOff + 1;
  var out2 = outOff + 2;
  var out3 = outOff + 3;

  var wn4r = this.table[2], wn4i = this.table[3];
  var inv = this._inv ? -1 : 1;
  var r0 = data[off];
  var r1 = data[off + 1];
  var r2 = data[off + 2];
  var r3 = data[off + 3];

  var a0r = r0 + r2, a0i = r1 + r3;
  var a1r = r0 - r2, a1i = r1 - r3;

  var m0r = wn4r * a0i, m0i = -wn4r * a0r;
  var m1r = wn4r * a1i * inv, m1i = wn4r * a1r * inv;

  out[out0] = a0r + m0r;
  out[out1] = a0i + m0i;
  out[out2] = a1r + m1r;
  out[out3] = a1i + m1i;
};

FFT.prototype._singleReal4Transform4 = function _singleReal4Transform4(outOff, off) {
  var out = this._out;
  var data = this._data;
  var inv = this._inv ? -1 : 1;
  var wn4r = this.table[2], wn4i = this.table[3];

  var r0 = data[off];
  var r1 = data[off + 1];
  var r2 = data[off + 2];
  var r3 = data[off + 3];
  var r4 = data[off + 4];
  var r5 = data[off + 5];
  var r6 = data[off + 6];
  var r7 = data[off + 7];

  var a0r = r0 + r4, a0i = r1 + r5;
  var a1r = r0 - r4, a1i = r1 - r5;
  var a2r = r2 + r6, a2i = r3 + r7;
  var a3r = r2 - r6, a3i = r3 - r7;

  var b0r = a0r + a2r, b0i = a0i + a2i;
  var b1r = a1r + a3i * inv, b1i = a1i - a3r * inv;
  var b2r = a0r - a2r, b2i = a0i - a2i;
  var b3r = a1r - a3i * inv, b3i = a1i + a3r * inv;

  var c0r = b0r + wn4r * b0i, c0i = b0i - wn4r * b0r;
  var c1r = b1r + wn4r * b1i, c1i = b1i - wn4r * b1r;
  var c2r = b2r + wn4r * b2i, c2i = b2i - wn4r * b2r;
  var c3r = b3r + wn4r * b3i, c3i = b3i - wn4r * b3r;

  out[outOff] = c0r;
  out[outOff + 1] = c0i;
  out[outOff + 2] = c1r;
  out[outOff + 3] = c1i;
  out[outOff + 4] = c2r;
  out[outOff + 5] = c2i;
  out[outOff + 6] = c3r;
  out[outOff + 7] = c3i;
};

// Advanced spectrum analysis functions inspired by audioMotion-analyzer
var fftInstance = null;
var fftOutput = null;
var workerLoaded = false;

// Frequency scaling modes
var FREQ_SCALE_LINEAR = 0;
var FREQ_SCALE_LOG = 1;
var FREQ_SCALE_BARK = 2;
var FREQ_SCALE_MEL = 3;

// Bark scale conversion (perceptual frequency scale)
function freqToBark(freq) {
    return 13 * Math.atan(0.00076 * freq) + 3.5 * Math.atan(Math.pow(freq / 7500, 2));
}

// Mel scale conversion (perceptual frequency scale)
function freqToMel(freq) {
    return 2595 * Math.log10(1 + freq / 700);
}

// Generate frequency bands based on scale type
function generateFrequencyBands(barCount, minFreq, maxFreq, scaleType, sampleRate) {
    var bands = [];
    var i, freq, nextFreq;
    
    switch (scaleType) {
        case FREQ_SCALE_LINEAR:
            var step = (maxFreq - minFreq) / barCount;
            for (i = 0; i < barCount; i++) {
                freq = minFreq + i * step;
                nextFreq = minFreq + (i + 1) * step;
                bands.push({
                    center: (freq + nextFreq) / 2,
                    low: freq,
                    high: nextFreq,
                    binLow: Math.floor((freq / sampleRate) * fftInstance.size),
                    binHigh: Math.floor((nextFreq / sampleRate) * fftInstance.size)
                });
            }
            break;
            
        case FREQ_SCALE_LOG:
            var logMin = Math.log10(minFreq);
            var logMax = Math.log10(maxFreq);
            var logStep = (logMax - logMin) / barCount;
            for (i = 0; i < barCount; i++) {
                freq = Math.pow(10, logMin + i * logStep);
                nextFreq = Math.pow(10, logMin + (i + 1) * logStep);
                bands.push({
                    center: Math.sqrt(freq * nextFreq), // Geometric mean
                    low: freq,
                    high: nextFreq,
                    binLow: Math.floor((freq / sampleRate) * fftInstance.size),
                    binHigh: Math.floor((nextFreq / sampleRate) * fftInstance.size)
                });
            }
            break;
            
        case FREQ_SCALE_BARK:
            var barkMin = freqToBark(minFreq);
            var barkMax = freqToBark(maxFreq);
            var barkStep = (barkMax - barkMin) / barCount;
            for (i = 0; i < barCount; i++) {
                var bark = barkMin + i * barkStep;
                var nextBark = barkMin + (i + 1) * barkStep;
                // Inverse Bark scale approximation
                freq = 600 * Math.sinh(bark / 4);
                nextFreq = 600 * Math.sinh(nextBark / 4);
                bands.push({
                    center: (freq + nextFreq) / 2,
                    low: freq,
                    high: nextFreq,
                    binLow: Math.floor((freq / sampleRate) * fftInstance.size),
                    binHigh: Math.floor((nextFreq / sampleRate) * fftInstance.size)
                });
            }
            break;
            
        case FREQ_SCALE_MEL:
            var melMin = freqToMel(minFreq);
            var melMax = freqToMel(maxFreq);
            var melStep = (melMax - melMin) / barCount;
            for (i = 0; i < barCount; i++) {
                var mel = melMin + i * melStep;
                var nextMel = melMin + (i + 1) * melStep;
                // Inverse Mel scale
                freq = 700 * (Math.pow(10, mel / 2595) - 1);
                nextFreq = 700 * (Math.pow(10, nextMel / 2595) - 1);
                bands.push({
                    center: (freq + nextFreq) / 2,
                    low: freq,
                    high: nextFreq,
                    binLow: Math.floor((freq / sampleRate) * fftInstance.size),
                    binHigh: Math.floor((nextFreq / sampleRate) * fftInstance.size)
                });
            }
            break;
    }
    
    return bands;
}

// Main worker message handler
WorkerScript.onMessage = function(message) {
    if (message.type === 'analyze') {
        // Log version on first message
        if (!workerLoaded) {
            console.log("SpectrumWorkerAdvanced v1.0 - High-performance FFT with audioMotion features");
            workerLoaded = true;
        }
        
        var audioData = message.audioData || [];
        var sampleRate = message.sampleRate || 44100;
        var barCount = message.barCount || 32;
        var isPlaying = message.isPlaying || false;
        var volume = message.volume || 0.5;
        var fftSize = message.fftSize || 2048;
        var minFreq = message.minFreq || 50;
        var maxFreq = message.maxFreq || 8000;
        var freqScale = message.freqScale || FREQ_SCALE_LINEAR;
        
        var result = {
            type: 'spectrum',
            bars: [],
            timestamp: Date.now()
        };
        
        if (!isPlaying || audioData.length === 0) {
            // Return empty spectrum when not playing
            for (var i = 0; i < barCount; i++) {
                result.bars.push({
                    magnitude: 0,
                    peak: 0,
                    frequency: i / barCount
                });
            }
            WorkerScript.sendMessage(result);
            return;
        }
        
        // Initialize or resize FFT if needed
        if (!fftInstance || fftInstance.size !== fftSize) {
            try {
                fftInstance = new FFT(fftSize);
                fftOutput = fftInstance.createComplexArray();
                console.log("SpectrumWorkerAdvanced: Initialized FFT with size", fftSize);
            } catch (e) {
                console.log("SpectrumWorkerAdvanced: FFT initialization failed:", e);
                WorkerScript.sendMessage(result);
                return;
            }
        }
        
        // Prepare audio data for FFT
        var input = new Array(fftSize);
        for (var i = 0; i < fftSize; i++) {
            input[i] = i < audioData.length ? audioData[i] : 0;
        }
        
        // Apply Hann window to reduce spectral leakage
        for (var i = 0; i < fftSize; i++) {
            var window = 0.5 * (1 - Math.cos(2 * Math.PI * i / (fftSize - 1)));
            input[i] *= window;
        }
        
        // Perform high-performance FFT
        try {
            fftInstance.realTransform(fftOutput, input);
        } catch (e) {
            console.log("SpectrumWorkerAdvanced: FFT transform failed:", e);
            WorkerScript.sendMessage(result);
            return;
        }
        
        // Calculate magnitude spectrum
        var magnitudes = new Array(fftSize / 2);
        for (var i = 0; i < fftSize / 2; i++) {
            var real = fftOutput[i * 2];
            var imag = fftOutput[i * 2 + 1];
            magnitudes[i] = Math.sqrt(real * real + imag * imag);
        }
        
        // Generate frequency bands with selected scaling
        var freqBands = generateFrequencyBands(barCount, minFreq, maxFreq, freqScale, sampleRate);
        
        // Calculate magnitude for each frequency band
        for (var i = 0; i < barCount; i++) {
            var band = freqBands[i];
            var magnitude = 0;
            var count = 0;
            
            // Sum magnitudes in this frequency band
            var binLow = Math.max(0, band.binLow);
            var binHigh = Math.min(magnitudes.length - 1, band.binHigh);
            
            for (var bin = binLow; bin <= binHigh; bin++) {
                magnitude += magnitudes[bin];
                count++;
            }
            
            // Average and apply volume scaling
            if (count > 0) {
                magnitude = (magnitude / count) * volume;
                
                // Apply perceptual loudness scaling
                magnitude = Math.sqrt(magnitude);
                
                // Normalize for consistent visualization
                magnitude *= 2.0; // Boost for visibility
            }
            
            // Clamp to valid range
            magnitude = Math.min(1.0, Math.max(0, magnitude));
            
            result.bars.push({
                magnitude: magnitude,
                peak: magnitude * 1.1,
                frequency: band.center,
                freqRange: band.low.toFixed(0) + "-" + band.high.toFixed(0) + " Hz"
            });
        }
        
        WorkerScript.sendMessage(result);
    } else if (message.type === 'configure') {
        // Handle configuration changes
        console.log("SpectrumWorkerAdvanced: Configuration updated");
    }
};
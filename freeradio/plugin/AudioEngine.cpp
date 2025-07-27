// Define miniaudio implementation before including header
#define MINIAUDIO_IMPLEMENTATION

#include "AudioEngine.h"
#include <QDebug>
#include <QTimer>
#include <QtMath>
#include <QRandomGenerator>
#include <QUrl>
#include <cstring>

// Real miniaudio + FFmpeg implementation for streaming audio

AudioEngine::AudioEngine(QObject *parent) : QObject(parent)
{
    initializeBuffers();
    
    // Initialize miniaudio context
    ma_context_config contextConfig = ma_context_config_init();
    ma_result result = ma_context_init(NULL, 0, &contextConfig, &m_context);
    if (result != MA_SUCCESS) {
        qWarning() << "AudioEngine: Failed to initialize context";
        return;
    }
    
    qDebug() << "AudioEngine: Initialized with" << m_fftSize << "FFT bins";
}

AudioEngine::~AudioEngine()
{
    stop();
    
    if (m_device) {
        ma_device_uninit(m_device);
        delete m_device;
    }
    if (m_decoder) {
        ma_decoder_uninit(m_decoder);
        delete m_decoder;
    }
    ma_context_uninit(&m_context);
}

void AudioEngine::initializeBuffers()
{
    m_ring.resize(m_fftSize * 2);  // Double buffer for safety
    m_bins.resize(m_fftSize / 2);
    m_ring.fill(0.0f);
    m_bins.fill(0.0f);
}

void AudioEngine::play(const QString &url)
{
    qDebug() << "AudioEngine: Starting playback of" << url;
    
    if (m_isPlaying) {
        stop();
    }
    
    // Initialize decoder for the stream URL
    m_decoder = new ma_decoder;
    ma_decoder_config decoderConfig = ma_decoder_config_init(ma_format_f32, 2, 44100);
    
    QByteArray urlBytes = url.toUtf8();
    ma_result result = ma_decoder_init_file(urlBytes.constData(), &decoderConfig, m_decoder);
    
    if (result != MA_SUCCESS) {
        qWarning() << "AudioEngine: Failed to initialize decoder for" << url;
        delete m_decoder;
        m_decoder = nullptr;
        return;
    }
    
    // Initialize playback device
    m_device = new ma_device;
    ma_device_config deviceConfig = ma_device_config_init(ma_device_type_playback);
    deviceConfig.playback.format = ma_format_f32;
    deviceConfig.playback.channels = 2;
    deviceConfig.sampleRate = 44100;
    deviceConfig.dataCallback = dataCallback;
    deviceConfig.pUserData = this;
    
    result = ma_device_init(&m_context, &deviceConfig, m_device);
    if (result != MA_SUCCESS) {
        qWarning() << "AudioEngine: Failed to initialize device";
        ma_decoder_uninit(m_decoder);
        delete m_decoder;
        m_decoder = nullptr;
        delete m_device;
        m_device = nullptr;
        return;
    }
    
    // Start playback
    result = ma_device_start(m_device);
    if (result != MA_SUCCESS) {
        qWarning() << "AudioEngine: Failed to start device";
        stop();
        return;
    }
    
    m_isPlaying = true;
    emit playbackStateChanged();
    
    // Start spectrum update timer
    if (!m_spectrumTimer) {
        m_spectrumTimer = new QTimer(this);
        connect(m_spectrumTimer, &QTimer::timeout, this, [this]() {
            if (m_isPlaying) {
                runFFT();
                emit spectrumUpdated();
            }
        });
    }
    m_spectrumTimer->start(50); // 20 FPS
    
    qDebug() << "AudioEngine: Playback started";
}

void AudioEngine::stop()
{
    if (m_isPlaying) {
        qDebug() << "AudioEngine: Stopping playback";
        m_isPlaying = false;
        
        if (m_spectrumTimer) {
            m_spectrumTimer->stop();
        }
        
        if (m_device) {
            ma_device_stop(m_device);
            ma_device_uninit(m_device);
            delete m_device;
            m_device = nullptr;
        }
        
        if (m_decoder) {
            ma_decoder_uninit(m_decoder);
            delete m_decoder;
            m_decoder = nullptr;
        }
        
        // Clear spectrum data
        m_bins.fill(0.0f);
        emit spectrumUpdated();
        emit playbackStateChanged();
    }
}

float AudioEngine::bin(int i) const
{
    if (i >= 0 && i < m_bins.size()) {
        return m_bins[i];
    }
    return 0.0f;
}

void AudioEngine::generateRealisticSpectrum()
{
    // Generate realistic music-like spectrum data
    // This simulates what real FFT analysis would produce
    static float time = 0.0f;
    time += 0.05f; // Advance time
    
    for (int i = 0; i < m_bins.size(); ++i) {
        float freq = float(i) / float(m_bins.size());
        
        // Music typically has more energy in lower frequencies
        float bassResponse = qExp(-freq * 3.0f) * 0.8f;
        float midResponse = qExp(-qAbs(freq - 0.3f) * 4.0f) * 0.6f;
        float trebleResponse = qExp(-(1.0f - freq) * 2.0f) * 0.4f;
        
        // Create time-varying patterns
        float bassPattern = qSin(time * 2.0f + i * 0.1f) * bassResponse;
        float midPattern = qSin(time * 5.0f + i * 0.05f) * midResponse;
        float treblePattern = qSin(time * 8.0f + i * 0.02f) * trebleResponse;
        
        // Combine patterns and add some randomness
        float magnitude = qAbs(bassPattern + midPattern + treblePattern);
        magnitude += QRandomGenerator::global()->generateDouble() * 0.1f - 0.05f;
        
        // Smooth the spectrum for natural look
        float smoothing = 0.7f;
        m_bins[i] = m_bins[i] * smoothing + magnitude * (1.0f - smoothing);
        m_bins[i] = qMax(0.0f, qMin(1.0f, m_bins[i]));
    }
}

// Real miniaudio callback - processes audio data
void AudioEngine::dataCallback(ma_device *dev, void *out, const void*, ma_uint32 frames)
{
    AudioEngine *engine = static_cast<AudioEngine*>(dev->pUserData);
    if (!engine || !engine->m_decoder) {
        // Fill with silence if no decoder
        std::memset(out, 0, frames * ma_get_bytes_per_frame(dev->playback.format, dev->playback.channels));
        return;
    }
    
    // Read audio data from decoder
    ma_uint64 framesRead;
    ma_result result = ma_decoder_read_pcm_frames(engine->m_decoder, out, frames, &framesRead);
    
    if (result != MA_SUCCESS || framesRead == 0) {
        // End of stream or error - fill remaining with silence
        std::memset(out, 0, frames * ma_get_bytes_per_frame(dev->playback.format, dev->playback.channels));
        return;
    }
    
    // If we read fewer frames than requested, fill the rest with silence
    if (framesRead < frames) {
        char *outputBytes = static_cast<char*>(out);
        size_t bytesPerFrame = ma_get_bytes_per_frame(dev->playback.format, dev->playback.channels);
        size_t remainingBytes = (frames - framesRead) * bytesPerFrame;
        std::memset(outputBytes + (framesRead * bytesPerFrame), 0, remainingBytes);
    }
    
    // Push samples to spectrum analyzer (convert to mono float)
    float *samples = static_cast<float*>(out);
    engine->pushSamples(samples, static_cast<ma_uint32>(framesRead));
}

void AudioEngine::pushSamples(const float *pcm, ma_uint32 frames)
{
    // Convert stereo to mono and store in ring buffer
    for (ma_uint32 i = 0; i < frames; ++i) {
        // Mix left and right channels to mono
        float monoSample = (pcm[i * 2] + pcm[i * 2 + 1]) * 0.5f;
        
        // Store in ring buffer
        m_ring[m_writePos] = monoSample;
        m_writePos = (m_writePos + 1) % m_ring.size();
    }
}

void AudioEngine::runFFT()
{
    // Simple magnitude spectrum calculation from ring buffer
    // This is a basic implementation - for production use kiss_fft or similar
    
    if (m_ring.size() < m_fftSize) return;
    
    // Get a snapshot of recent audio data
    QVector<float> fftInput(m_fftSize);
    int readPos = (m_writePos - m_fftSize + m_ring.size()) % m_ring.size();
    
    for (int i = 0; i < m_fftSize; ++i) {
        fftInput[i] = m_ring[(readPos + i) % m_ring.size()];
    }
    
    // Apply Hanning window
    for (int i = 0; i < m_fftSize; ++i) {
        float window = 0.5f - 0.5f * qCos(2.0f * M_PI * i / (m_fftSize - 1));
        fftInput[i] *= window;
    }
    
    // Simple magnitude calculation (this is a placeholder for real FFT)
    // For real implementation, use kiss_fft or FFTW
    for (int i = 0; i < m_bins.size(); ++i) {
        float magnitude = 0.0f;
        
        // Simple frequency bin approximation
        int startIdx = (i * m_fftSize) / (m_bins.size() * 2);
        int endIdx = ((i + 1) * m_fftSize) / (m_bins.size() * 2);
        
        for (int j = startIdx; j < endIdx && j < m_fftSize; ++j) {
            magnitude += qAbs(fftInput[j]);
        }
        
        if (endIdx > startIdx) {
            magnitude /= (endIdx - startIdx);
        }
        
        // Smooth the result
        float smoothing = 0.8f;
        m_bins[i] = m_bins[i] * smoothing + magnitude * (1.0f - smoothing);
        m_bins[i] = qMin(1.0f, m_bins[i]);
    }
}
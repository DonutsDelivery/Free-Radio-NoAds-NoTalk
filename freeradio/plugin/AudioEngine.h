#pragma once
#include <QObject>
#include <QVector>
#include <QQmlEngine>
#include <QTimer>

// Miniaudio with FFmpeg support for all codecs
#include "miniaudio.h"

class AudioEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT                       // exposes the type to QML
    
public:
    explicit AudioEngine(QObject *parent = nullptr);
    ~AudioEngine();
    
    Q_INVOKABLE void play(const QString &url);
    Q_INVOKABLE void stop();
    Q_INVOKABLE int  spectrumBins() const { return m_fftSize / 2; }
    Q_INVOKABLE float bin(int i) const;
    Q_INVOKABLE bool isPlaying() const { return m_isPlaying; }

signals:
    void spectrumUpdated();        // emitted ~20 ×/s
    void playbackStateChanged();

private:
    static void dataCallback(ma_device *dev, void *out, const void*, ma_uint32 frames);
    void pushSamples(const float *pcm, ma_uint32 frames);
    void runFFT();                 // Simple FFT implementation
    void generateRealisticSpectrum(); // Generate realistic spectrum for demo
    
    ma_context     m_context;
    ma_decoder     *m_decoder = nullptr;
    ma_device      *m_device = nullptr;
    QTimer         *m_spectrumTimer = nullptr;
    QVector<float> m_ring;         // 2×fftSize circular buffer
    QVector<float> m_bins;         // magnitude spectrum
    int            m_writePos = 0;
    const int      m_fftSize  = 1024;
    bool           m_isPlaying = false;
    
    void initializeBuffers();
};
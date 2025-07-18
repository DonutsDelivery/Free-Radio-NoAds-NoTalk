#include "AudioCapture.h"
#include <QDebug>
#include <QAudioFormat>
#include <QAudioDevice>
#include <QMediaDevices>
#include <pulse/pulseaudio.h>
#include <pulse/simple.h>

AudioCapture::AudioCapture(QObject *parent) : QObject(parent), audioInput(nullptr), audioDevice(nullptr)
{
    // Initialize PulseAudio for system audio capture
    initializePulseAudio();
}

AudioCapture::~AudioCapture()
{
    stopCapture();
}

void AudioCapture::initializePulseAudio()
{
    // PulseAudio setup for capturing system audio output
    pa_sample_spec ss;
    ss.format = PA_SAMPLE_FLOAT32LE;
    ss.channels = 2;
    ss.rate = 44100;
    
    // Create a simple connection to capture from monitor source
    // This captures what's being played on the system
    pa_simple *s = pa_simple_new(
        NULL,                    // Use default server
        "FreeRadio Spectrum",    // Application name
        PA_STREAM_RECORD,        // Record stream
        "@DEFAULT_MONITOR@",     // Default monitor source (system output)
        "Audio Visualization",   // Stream description
        &ss,                     // Sample format
        NULL,                    // Default channel map
        NULL,                    // Default buffering attributes
        NULL                     // Error code
    );
    
    if (s) {
        pulseAudioConnection = s;
        qDebug() << "PulseAudio capture initialized successfully";
        
        // Start capture timer
        captureTimer = new QTimer(this);
        connect(captureTimer, &QTimer::timeout, this, &AudioCapture::captureAudioData);
        captureTimer->start(20); // 50 FPS
    } else {
        qDebug() << "Failed to initialize PulseAudio capture";
    }
}

void AudioCapture::captureAudioData()
{
    if (!pulseAudioConnection) return;
    
    // Buffer for audio samples
    const int bufferSize = 1024;
    float buffer[bufferSize];
    
    // Read audio data from PulseAudio monitor
    int error;
    if (pa_simple_read(pulseAudioConnection, buffer, sizeof(buffer), &error) < 0) {
        qDebug() << "PulseAudio read error:" << pa_strerror(error);
        return;
    }
    
    // Convert to QVariantList for QML
    QVariantList audioData;
    for (int i = 0; i < bufferSize; ++i) {
        audioData.append(buffer[i]);
    }
    
    // Emit signal with real audio data
    emit audioDataReady(audioData);
}

void AudioCapture::startCapture()
{
    if (captureTimer && !captureTimer->isActive()) {
        captureTimer->start(20);
        qDebug() << "Audio capture started";
    }
}

void AudioCapture::stopCapture()
{
    if (captureTimer) {
        captureTimer->stop();
    }
    
    if (pulseAudioConnection) {
        pa_simple_free(pulseAudioConnection);
        pulseAudioConnection = nullptr;
    }
    
    qDebug() << "Audio capture stopped";
}
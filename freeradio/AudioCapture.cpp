#include "AudioCapture.h"
#include <QDebug>

#ifdef HAVE_PULSEAUDIO
#include <pulse/pulseaudio.h>
#include <pulse/simple.h>
#endif

AudioCapture::AudioCapture(QObject *parent) : QObject(parent)
{
    startCapture();
}

AudioCapture::~AudioCapture()
{
    stopCapture();
}

#ifdef HAVE_PULSEAUDIO
pa_simple *AudioCapture::createPulseConnection()
{
    pa_sample_spec ss;
    ss.format = PA_SAMPLE_FLOAT32LE;
    ss.channels = 2;
    ss.rate = 44100;

    // Set buffer attributes to avoid excessive latency
    pa_buffer_attr attr;
    memset(&attr, 0, sizeof(attr));
    attr.maxlength = (uint32_t)-1;
    attr.fragsize = 4096; // 1024 floats = ~11.6ms at 44100 Hz stereo

    int error;
    pa_simple *s = pa_simple_new(
        NULL,                    // Use default server
        "FreeRadio Spectrum",    // Application name
        PA_STREAM_RECORD,        // Record stream
        "@DEFAULT_MONITOR@",     // Default monitor source (system output)
        "Audio Visualization",   // Stream description
        &ss,                     // Sample format
        NULL,                    // Default channel map
        &attr,                   // Buffer attributes
        &error                   // Error code
    );

    if (!s) {
        qDebug() << "Failed to create PulseAudio connection:" << pa_strerror(error);
    }
    return s;
}
#endif

void AudioCapture::startCapture()
{
    if (m_running.load()) return;

#ifdef HAVE_PULSEAUDIO
    m_running.store(true);
    m_active = true;
    emit isActiveChanged();

    m_captureThread = QThread::create([this]() { captureLoop(); });
    m_captureThread->setObjectName("AudioCaptureThread");
    m_captureThread->start();

    qDebug() << "Audio capture started (threaded)";
#else
    qDebug() << "PulseAudio not available on this platform";
#endif
}

void AudioCapture::stopCapture()
{
    m_running.store(false);

    if (m_captureThread) {
        // Wait for the capture thread to finish; the blocking pa_simple_read
        // will complete once the current fragment is delivered
        if (!m_captureThread->wait(3000)) {
            qWarning() << "Audio capture thread did not stop in time";
            m_captureThread->terminate();
            m_captureThread->wait(1000);
        }
        delete m_captureThread;
        m_captureThread = nullptr;
    }

    if (m_active) {
        m_active = false;
        emit isActiveChanged();
    }

    qDebug() << "Audio capture stopped";
}

void AudioCapture::captureLoop()
{
#ifdef HAVE_PULSEAUDIO
    pa_simple *connection = createPulseConnection();
    if (!connection) {
        qWarning() << "Failed to initialize PulseAudio capture";
        return;
    }

    qDebug() << "PulseAudio capture thread running";

    const int bufferSize = 1024;
    float buffer[bufferSize];

    while (m_running.load(std::memory_order_relaxed)) {
        int error;
        if (pa_simple_read(connection, buffer, sizeof(buffer), &error) < 0) {
            if (!m_running.load()) break; // Clean shutdown

            qDebug() << "PulseAudio read error:" << pa_strerror(error);

            // Connection lost — try to reconnect with backoff
            pa_simple_free(connection);
            connection = nullptr;

            for (int attempt = 0; attempt < 10 && m_running.load(); ++attempt) {
                QThread::msleep(500);
                if (!m_running.load()) break;

                connection = createPulseConnection();
                if (connection) {
                    qDebug() << "PulseAudio reconnected after" << (attempt + 1) << "attempt(s)";
                    break;
                }
            }

            if (!connection) {
                qWarning() << "Failed to reconnect PulseAudio after retries, stopping capture";
                break;
            }
            continue;
        }

        // Convert to QVariantList for QML
        QVariantList audioData;
        audioData.reserve(bufferSize);
        for (int i = 0; i < bufferSize; ++i) {
            audioData.append(buffer[i]);
        }

        // Post to main thread via queued connection
        QMetaObject::invokeMethod(this, [this, audioData = std::move(audioData)]() {
            emit audioDataReady(audioData);
        }, Qt::QueuedConnection);
    }

    if (connection) {
        pa_simple_free(connection);
    }

    qDebug() << "PulseAudio capture thread exiting";
#endif
}

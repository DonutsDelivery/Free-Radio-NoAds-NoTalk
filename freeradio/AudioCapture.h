#ifndef AUDIOCAPTURE_H
#define AUDIOCAPTURE_H

#include <QObject>
#include <QThread>
#include <QVariantList>
#include <atomic>

#ifdef HAVE_PULSEAUDIO
typedef struct pa_simple pa_simple;
#endif

class AudioCapture : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isActive READ isActive NOTIFY isActiveChanged)

public:
    explicit AudioCapture(QObject *parent = nullptr);
    ~AudioCapture();

    bool isActive() const { return m_active; }

    Q_INVOKABLE void startCapture();
    Q_INVOKABLE void stopCapture();

signals:
    void audioDataReady(QVariantList audioData);
    void isActiveChanged();

private:
    void captureLoop();

#ifdef HAVE_PULSEAUDIO
    pa_simple *createPulseConnection();
#endif

    QThread *m_captureThread = nullptr;
    std::atomic<bool> m_running{false};
    bool m_active = false;
};

#endif // AUDIOCAPTURE_H

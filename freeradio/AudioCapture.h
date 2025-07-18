#ifndef AUDIOCAPTURE_H
#define AUDIOCAPTURE_H

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QAudioInput>
#include <QIODevice>

// Forward declare PulseAudio types
typedef struct pa_simple pa_simple;

class AudioCapture : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isActive READ isActive NOTIFY isActiveChanged)
    
public:
    explicit AudioCapture(QObject *parent = nullptr);
    ~AudioCapture();
    
    bool isActive() const { return captureTimer && captureTimer->isActive(); }
    
    Q_INVOKABLE void startCapture();
    Q_INVOKABLE void stopCapture();
    
signals:
    void audioDataReady(QVariantList audioData);
    void isActiveChanged();
    
private slots:
    void captureAudioData();
    
private:
    void initializePulseAudio();
    
    QTimer *captureTimer = nullptr;
    QAudioInput *audioInput = nullptr;
    QIODevice *audioDevice = nullptr;
    pa_simple *pulseAudioConnection = nullptr;
};

#endif // AUDIOCAPTURE_H
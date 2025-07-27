#include <QCoreApplication>
#include <QDebug>
#include <QTimer>
#include "AudioCapture.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    
    qDebug() << "Testing AudioCapture component...";
    
    AudioCapture audioCapture;
    
    // Connect to audio data signal
    QObject::connect(&audioCapture, &AudioCapture::audioDataReady, 
                     [](const QVariantList& data) {
        qDebug() << "Audio data received, length:" << data.length();
        if (data.length() > 0) {
            qDebug() << "First 5 samples:" << data.mid(0, 5);
        }
    });
    
    qDebug() << "Starting audio capture...";
    audioCapture.startCapture();
    
    // Run for 10 seconds then exit
    QTimer::singleShot(10000, &app, &QCoreApplication::quit);
    
    qDebug() << "Running for 10 seconds...";
    return app.exec();
}
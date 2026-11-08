#pragma once

#include <QObject>
#include <QString>

class AndroidMediaIntegration final : public QObject
{
    Q_OBJECT

public:
    explicit AndroidMediaIntegration(QObject *parent = nullptr);
    ~AndroidMediaIntegration() override;

    Q_INVOKABLE void updatePlaybackState(bool playing,
                                         const QString &station,
                                         const QString &track = {});
    Q_INVOKABLE void stopService();

signals:
    void playRequested();
    void pauseRequested();
    void stopRequested();
    void nextRequested();
    void previousRequested();

#ifdef Q_OS_ANDROID
public:
    static AndroidMediaIntegration *s_instance;
#endif
};

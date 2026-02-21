#ifndef SESSIONMONITOR_H
#define SESSIONMONITOR_H

#include <QObject>

class SessionMonitor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool screenLocked READ isScreenLocked NOTIFY screenLockedChanged)
    Q_PROPERTY(bool inhibitActive READ isInhibitActive NOTIFY inhibitActiveChanged)

public:
    explicit SessionMonitor(QObject *parent = nullptr);
    ~SessionMonitor();

    bool isScreenLocked() const { return m_locked; }
    bool isInhibitActive() const { return m_inhibitCookie != 0; }

    // Call from QML when playback starts/stops
    Q_INVOKABLE void inhibitIdle(const QString &reason = "Playing audio stream");
    Q_INVOKABLE void uninhibitIdle();

signals:
    void screenLockedChanged(bool locked);
    void screenUnlocked();
    void inhibitActiveChanged();

private slots:
    void onScreenSaverActiveChanged(bool active);

private:
    void connectDBusSignals();
    bool m_locked = false;
    quint32 m_inhibitCookie = 0;
};

#endif // SESSIONMONITOR_H

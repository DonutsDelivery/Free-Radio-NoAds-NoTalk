#include "SessionMonitor.h"
#include <QDebug>

#ifdef QT_DBUS_LIB
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#endif

SessionMonitor::SessionMonitor(QObject *parent) : QObject(parent)
{
    connectDBusSignals();
}

SessionMonitor::~SessionMonitor()
{
    uninhibitIdle();
}

void SessionMonitor::connectDBusSignals()
{
#ifdef QT_DBUS_LIB
    auto bus = QDBusConnection::sessionBus();
    bus.connect("org.freedesktop.ScreenSaver", "/org/freedesktop/ScreenSaver",
                "org.freedesktop.ScreenSaver", "ActiveChanged",
                this, SLOT(onScreenSaverActiveChanged(bool)));
    bus.connect("org.gnome.ScreenSaver", "/org/gnome/ScreenSaver",
                "org.gnome.ScreenSaver", "ActiveChanged",
                this, SLOT(onScreenSaverActiveChanged(bool)));
    qDebug() << "SessionMonitor: listening for screen lock/unlock signals";
#endif
}

void SessionMonitor::onScreenSaverActiveChanged(bool active)
{
    if (m_locked == active)
        return;
    m_locked = active;
    emit screenLockedChanged(active);
    if (!active)
        emit screenUnlocked();
}

void SessionMonitor::inhibitIdle(const QString &reason)
{
#ifdef QT_DBUS_LIB
    if (m_inhibitCookie != 0)
        return;

    QDBusInterface iface("org.gnome.SessionManager", "/org/gnome/SessionManager",
                         "org.gnome.SessionManager", QDBusConnection::sessionBus());
    if (iface.isValid()) {
        QDBusReply<quint32> reply = iface.call("Inhibit", "FreeRadio", quint32(0),
                                               reason, quint32(12));
        if (reply.isValid()) {
            m_inhibitCookie = reply.value();
            emit inhibitActiveChanged();
            return;
        }
    }

    QDBusInterface fallback("org.freedesktop.ScreenSaver",
                            "/org/freedesktop/ScreenSaver",
                            "org.freedesktop.ScreenSaver",
                            QDBusConnection::sessionBus());
    if (fallback.isValid()) {
        QDBusReply<quint32> reply = fallback.call("Inhibit", "FreeRadio", reason);
        if (reply.isValid()) {
            m_inhibitCookie = reply.value();
            emit inhibitActiveChanged();
            return;
        }
    }
    qWarning() << "SessionMonitor: could not inhibit idle on any D-Bus interface";
#else
    Q_UNUSED(reason)
#endif
}

void SessionMonitor::uninhibitIdle()
{
#ifdef QT_DBUS_LIB
    if (m_inhibitCookie == 0)
        return;

    QDBusInterface iface("org.gnome.SessionManager", "/org/gnome/SessionManager",
                         "org.gnome.SessionManager", QDBusConnection::sessionBus());
    if (iface.isValid()) {
        iface.call("Uninhibit", m_inhibitCookie);
    } else {
        QDBusInterface fallback("org.freedesktop.ScreenSaver",
                                "/org/freedesktop/ScreenSaver",
                                "org.freedesktop.ScreenSaver",
                                QDBusConnection::sessionBus());
        if (fallback.isValid())
            fallback.call("UnInhibit", m_inhibitCookie);
    }
    m_inhibitCookie = 0;
    emit inhibitActiveChanged();
#endif
}

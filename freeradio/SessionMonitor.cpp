#include "SessionMonitor.h"
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDebug>

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
    auto bus = QDBusConnection::sessionBus();

    // freedesktop standard (works on KDE and some other DEs)
    bus.connect(
        "org.freedesktop.ScreenSaver",
        "/org/freedesktop/ScreenSaver",
        "org.freedesktop.ScreenSaver",
        "ActiveChanged",
        this, SLOT(onScreenSaverActiveChanged(bool))
    );

    // GNOME-specific screensaver
    bus.connect(
        "org.gnome.ScreenSaver",
        "/org/gnome/ScreenSaver",
        "org.gnome.ScreenSaver",
        "ActiveChanged",
        this, SLOT(onScreenSaverActiveChanged(bool))
    );

    qDebug() << "SessionMonitor: listening for screen lock/unlock signals";
}

void SessionMonitor::onScreenSaverActiveChanged(bool active)
{
    if (m_locked == active) return;

    m_locked = active;
    emit screenLockedChanged(active);

    qDebug() << "SessionMonitor: screen" << (active ? "locked" : "unlocked");

    if (!active) {
        emit screenUnlocked();
    }
}

void SessionMonitor::inhibitIdle(const QString &reason)
{
    if (m_inhibitCookie != 0) return; // Already inhibited

    QDBusInterface iface(
        "org.gnome.SessionManager",
        "/org/gnome/SessionManager",
        "org.gnome.SessionManager",
        QDBusConnection::sessionBus()
    );

    if (iface.isValid()) {
        // Inhibit flags: 4 = suspend, 8 = idle (prevent DPMS/screen off)
        QDBusReply<quint32> reply = iface.call("Inhibit", "FreeRadio", quint32(0), reason, quint32(12));
        if (reply.isValid()) {
            m_inhibitCookie = reply.value();
            emit inhibitActiveChanged();
            qDebug() << "SessionMonitor: idle/suspend inhibited (cookie:" << m_inhibitCookie << ")";
            return;
        }
        qDebug() << "SessionMonitor: GNOME inhibit failed:" << reply.error().message();
    }

    // Fallback: freedesktop ScreenSaver inhibit (works on KDE and others)
    QDBusInterface fdIface(
        "org.freedesktop.ScreenSaver",
        "/org/freedesktop/ScreenSaver",
        "org.freedesktop.ScreenSaver",
        QDBusConnection::sessionBus()
    );

    if (fdIface.isValid()) {
        QDBusReply<quint32> reply = fdIface.call("Inhibit", "FreeRadio", reason);
        if (reply.isValid()) {
            m_inhibitCookie = reply.value();
            emit inhibitActiveChanged();
            qDebug() << "SessionMonitor: screensaver inhibited via freedesktop (cookie:" << m_inhibitCookie << ")";
            return;
        }
        qDebug() << "SessionMonitor: freedesktop inhibit failed:" << reply.error().message();
    }

    qWarning() << "SessionMonitor: could not inhibit idle on any D-Bus interface";
}

void SessionMonitor::uninhibitIdle()
{
    if (m_inhibitCookie == 0) return;

    // Try GNOME first
    QDBusInterface iface(
        "org.gnome.SessionManager",
        "/org/gnome/SessionManager",
        "org.gnome.SessionManager",
        QDBusConnection::sessionBus()
    );

    if (iface.isValid()) {
        iface.call("Uninhibit", m_inhibitCookie);
        qDebug() << "SessionMonitor: idle/suspend uninhibited (cookie:" << m_inhibitCookie << ")";
        m_inhibitCookie = 0;
        emit inhibitActiveChanged();
        return;
    }

    // Fallback: freedesktop
    QDBusInterface fdIface(
        "org.freedesktop.ScreenSaver",
        "/org/freedesktop/ScreenSaver",
        "org.freedesktop.ScreenSaver",
        QDBusConnection::sessionBus()
    );

    if (fdIface.isValid()) {
        fdIface.call("UnInhibit", m_inhibitCookie);
        qDebug() << "SessionMonitor: screensaver uninhibited via freedesktop (cookie:" << m_inhibitCookie << ")";
    }

    m_inhibitCookie = 0;
    emit inhibitActiveChanged();
}

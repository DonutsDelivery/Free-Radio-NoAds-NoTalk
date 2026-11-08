#include <QtGlobal>
#ifdef Q_OS_ANDROID
#include <QGuiApplication>
#else
#include <QApplication>
#endif
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QIcon>
#include <QDir>
#include <QSettings>
#include <QStringList>
#include <memory>
#include "AudioCapture.h"
#include "AndroidMediaIntegration.h"
#include "SessionMonitor.h"

static const char kAppId[] = "online.donutsdelivery.DonutRadio";

// Copy settings saved under the old "Free Radio" identity into the DonutRadio
// location on first run. QSettings resolves its file from the application,
// organization and domain names, so each identity is set before its QSettings
// object is built. Nothing is copied once the new location holds any value.
static void migrateLegacySettings()
{
    QCoreApplication::setOrganizationName("FreeRadio");
    QCoreApplication::setOrganizationDomain("freeradio.app");
    QCoreApplication::setApplicationName("Free Radio");
    QSettings legacy;
    const QStringList keys = legacy.allKeys();

    QCoreApplication::setOrganizationName("DonutsDelivery");
    QCoreApplication::setOrganizationDomain("donutsdelivery.online");
    QCoreApplication::setApplicationName("DonutRadio");

    if (keys.isEmpty()) return;
    QSettings current;
    if (!current.allKeys().isEmpty()) return;
    for (const QString &key : keys) {
        current.setValue(key, legacy.value(key));
    }
    current.sync();
}

// Window icon: the installed theme icon, else the copy bundled in the binary
// (AppImage, Windows, macOS and uninstalled builds have no icon theme entry).
static QIcon appIcon()
{
    QIcon icon = QIcon::fromTheme(kAppId);
    if (!icon.isNull()) return icon;
    for (int size : {32, 64, 128, 256}) {
        icon.addFile(QStringLiteral(":/icons/%1.png").arg(size), QSize(size, size));
    }
    return icon;
}

int main(int argc, char *argv[])
{
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    // Force PulseAudio API instead of native PipeWire protocol.
    // Native PipeWire sets PW_STREAM_FLAG_DONT_RECONNECT which kills the stream
    // when monitors DPMS off during screen lock (graph reconfiguration).
    // PulseAudio via pipewire-pulse has a ~500ms ring buffer that survives this.
    qputenv("QT_AUDIO_BACKEND", "pulseaudio");
#endif

    // Enable GPU acceleration where available
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

#ifdef Q_OS_ANDROID
    QGuiApplication app(argc, argv);
#else
    QApplication app(argc, argv);
#endif

    app.setApplicationVersion("2.0.0");
    migrateLegacySettings();  // sets the application, organization and domain names
    // Wayland app_id and X11 class must match the installed desktop file.
    QGuiApplication::setDesktopFileName(kAppId);
    app.setWindowIcon(appIcon());

    // Use a native mobile control style; desktop keeps the KDE integration.
    if (QQuickStyle::name().isEmpty()) {
#ifdef Q_OS_ANDROID
        QQuickStyle::setStyle("Material");
#else
        QQuickStyle::setStyle("org.kde.desktop");
#endif
    }

    // Register types with QML
    qmlRegisterType<AudioCapture>("AudioCapture", 1, 0, "AudioCapture");
    qmlRegisterType<SessionMonitor>("SessionMonitor", 1, 0, "SessionMonitor");

    QQmlApplicationEngine engine;
    // qt_add_qml_module places FreeRadio.Audio beside the build output under
    // qml/. Installed builds also find it through Qt's standard import path.
    engine.addImportPath(QCoreApplication::applicationDirPath() + "/qml");

#ifdef FREERADIO_AUDIO_CORE_AVAILABLE
#ifdef FREERADIO_BUILD_QML_IMPORT_PATH
    engine.addImportPath(QStringLiteral(FREERADIO_BUILD_QML_IMPORT_PATH));
#endif
    const QString appDir = QCoreApplication::applicationDirPath();
    engine.addImportPath(QDir::cleanPath(appDir + QStringLiteral("/qml")));
    engine.addImportPath(QDir::cleanPath(appDir + QStringLiteral("/../Resources/qml")));
    engine.addImportPath(QDir::cleanPath(appDir + QStringLiteral("/../lib/qt6/qml")));
    if (app.arguments().contains(QStringLiteral("--audio-qml-smoke"))) {
        QQmlComponent smoke(&engine);
        smoke.setData("import QtQml\nimport FreeRadio.Audio 1.0\nAudioEngine {}", QUrl());
        std::unique_ptr<QObject> instance(smoke.create());
        if (!instance) {
            qCritical().noquote() << smoke.errorString();
            return 2;
        }
        return 0;
    }
#endif
    AndroidMediaIntegration androidMedia;
    engine.rootContext()->setContextProperty("AndroidMedia", &androidMedia);

    // Try to load from Qt resources first (bundled app)
    QUrl qmlUrl = QUrl("qrc:/ui/main.qml");

    // If not bundled, try local filesystem paths for development
    if (!QFile::exists(":/ui/main.qml")) {
        QStringList searchPaths = {
            QDir::currentPath() + "/contents/ui/main_standalone.qml",
            QCoreApplication::applicationDirPath() + "/contents/ui/main_standalone.qml",
            QCoreApplication::applicationDirPath() + "/../share/donutradio/ui/main_standalone.qml"
        };

        for (const QString& path : searchPaths) {
            if (QFile::exists(path)) {
                qmlUrl = QUrl::fromLocalFile(path);
                qDebug() << "Loading QML from filesystem:" << path;
                break;
            }
        }
    } else {
        qDebug() << "Loading QML from resources";
    }

    engine.load(qmlUrl);

    if (engine.rootObjects().isEmpty()) {
        qWarning() << "Failed to load QML. Tried:" << qmlUrl;
        return -1;
    }

    qDebug() << "DonutRadio started successfully";

    return app.exec();
}

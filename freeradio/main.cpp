#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QIcon>
#include <QDir>
#include <memory>
#include "AudioCapture.h"
#include "SessionMonitor.h"

int main(int argc, char *argv[])
{
    // Force PulseAudio API instead of native PipeWire protocol.
    // Native PipeWire sets PW_STREAM_FLAG_DONT_RECONNECT which kills the stream
    // when monitors DPMS off during screen lock (graph reconfiguration).
    // PulseAudio via pipewire-pulse has a ~500ms ring buffer that survives this.
    qputenv("QT_AUDIO_BACKEND", "pulseaudio");

    // Enable GPU acceleration where available
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

    QApplication app(argc, argv);

    app.setApplicationName("Free Radio");
    app.setApplicationVersion("2.0.0");
    app.setOrganizationName("FreeRadio");
    app.setOrganizationDomain("freeradio.app");
    app.setWindowIcon(QIcon::fromTheme("radio"));

    // Use appropriate style per platform
    // Try org.kde.desktop first (KDE), fall back to Fusion (works everywhere)
    if (QQuickStyle::name().isEmpty()) {
        QQuickStyle::setStyle("org.kde.desktop");
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

    // Try to load from Qt resources first (bundled app)
    QUrl qmlUrl = QUrl("qrc:/ui/main.qml");

    // If not bundled, try local filesystem paths for development
    if (!QFile::exists(":/ui/main.qml")) {
        QStringList searchPaths = {
            QDir::currentPath() + "/contents/ui/main_standalone.qml",
            QCoreApplication::applicationDirPath() + "/contents/ui/main_standalone.qml",
            QCoreApplication::applicationDirPath() + "/../share/freeradio/ui/main_standalone.qml"
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

    qDebug() << "Free Radio started successfully";

    return app.exec();
}

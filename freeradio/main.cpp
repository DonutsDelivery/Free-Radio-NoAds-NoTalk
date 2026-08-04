#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QIcon>
#include <QDir>
#include <QFileInfo>
#include "AudioCapture.h"
#include "SessionMonitor.h"

int main(int argc, char *argv[])
{
#if defined(Q_OS_LINUX)
    // Force PulseAudio API instead of native PipeWire protocol.
    // Native PipeWire sets PW_STREAM_FLAG_DONT_RECONNECT which kills the stream
    // when monitors DPMS off during screen lock (graph reconfiguration).
    // PulseAudio via pipewire-pulse has a ~500ms ring buffer that survives this.
    qputenv("QT_AUDIO_BACKEND", "pulseaudio");
#elif defined(Q_OS_MACOS)
    // Keep macOS on the stable Darwin multimedia backend by default. The
    // optional FFmpeg backend can be enabled explicitly for diagnostics with
    // FREERADIO_MEDIA_BACKEND=ffmpeg; some audio-device/stream combinations
    // can otherwise crash while FFmpeg initializes its resampler.
    if (qEnvironmentVariable("FREERADIO_MEDIA_BACKEND").compare("ffmpeg", Qt::CaseInsensitive) == 0) {
        const QString executableDir = QFileInfo(QString::fromLocal8Bit(argv[0])).absolutePath();
        const QString ffmpegPlugin = QDir(executableDir).absoluteFilePath(
                "../PlugIns/multimedia/libffmpegmediaplugin.dylib");
        if (QFileInfo::exists(ffmpegPlugin))
            qputenv("QT_MEDIA_BACKEND", "ffmpeg");
    }
#endif

    // Enable GPU acceleration where available
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

    QApplication app(argc, argv);

    app.setApplicationName("Free Radio");
    app.setApplicationVersion("2.0.0");
    app.setOrganizationName("FreeRadio");
    app.setOrganizationDomain("freeradio.app");
    QIcon appIcon(":/icons/freeradio.png");
    if (appIcon.isNull()) {
        appIcon = QIcon::fromTheme("radio");
    }
    app.setWindowIcon(appIcon);

    // The UI customizes control backgrounds and content items, which the
    // native macOS style intentionally does not allow. Fusion keeps those
    // controls usable while retaining the app's own visual design.
#if defined(Q_OS_MACOS)
    QQuickStyle::setStyle("Fusion");
#elif defined(Q_OS_LINUX)
    // Try org.kde.desktop first (KDE), fall back to Fusion (works everywhere)
    if (QQuickStyle::name().isEmpty()) {
        QQuickStyle::setStyle("org.kde.desktop");
    }
#else
    if (QQuickStyle::name().isEmpty()) {
        QQuickStyle::setStyle("Fusion");
    }
#endif

    // Register types with QML
    qmlRegisterType<AudioCapture>("AudioCapture", 1, 0, "AudioCapture");
    qmlRegisterType<SessionMonitor>("SessionMonitor", 1, 0, "SessionMonitor");

    QQmlApplicationEngine engine;

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

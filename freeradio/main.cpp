#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QIcon>
#include <QDir>
#include "AudioCapture.h"

int main(int argc, char *argv[])
{
    // Enable GPU acceleration where available
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

    QApplication app(argc, argv);

    app.setApplicationName("Free Radio");
    app.setApplicationVersion("2.0.0");
    app.setOrganizationName("FreeRadio");
    app.setOrganizationDomain("freeradio.app");
    app.setWindowIcon(QIcon::fromTheme("radio"));

    // Use appropriate style per platform
#ifdef Q_OS_LINUX
    // Use KDE style on Linux if available
    QQuickStyle::setStyle("org.kde.desktop");
#else
    // Use Fusion style on Windows/macOS for consistent look
    QQuickStyle::setStyle("Fusion");
#endif

    // Register the AudioCapture type with QML
    qmlRegisterType<AudioCapture>("AudioCapture", 1, 0, "AudioCapture");

    QQmlApplicationEngine engine;

    // Try to load from Qt resources first (bundled app)
    QUrl qmlUrl = QUrl("qrc:/ui/main.qml");

    // If not bundled, try local filesystem paths for development
    if (!QFile::exists(":/ui/main.qml")) {
        QStringList searchPaths = {
            QDir::currentPath() + "/contents/ui/main.qml",
            QCoreApplication::applicationDirPath() + "/contents/ui/main.qml",
            QCoreApplication::applicationDirPath() + "/../share/freeradio/ui/main.qml"
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

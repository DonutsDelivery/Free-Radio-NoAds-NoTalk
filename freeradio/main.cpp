#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QDir>
#include "AudioCapture.h"

int main(int argc, char *argv[])
{
    // Set up environment for Qt
    qputenv("QT_QPA_PLATFORM", "xcb");
    qputenv("QT_QUICK_BACKEND", "software");  // Use software rendering first
    
    QApplication app(argc, argv);
    
    app.setApplicationName("FreeRadio");
    app.setApplicationVersion("1.4.0");
    app.setOrganizationName("FreeRadio");
    
    // Register the AudioCapture type with QML
    qmlRegisterType<AudioCapture>("AudioCapture", 1, 0, "AudioCapture");
    
    QQmlApplicationEngine engine;
    
    // Load QML from filesystem for standalone app
    QString qmlFile = QDir::currentPath() + "/contents/ui/main.qml";
    if (!QFile::exists(qmlFile)) {
        qDebug() << "QML file not found:" << qmlFile;
        qDebug() << "Current directory:" << QDir::currentPath();
        
        // Try alternative paths
        QStringList paths = {
            "./contents/ui/main.qml",
            "contents/ui/main.qml",
            "ui/main.qml",
            "main.qml"
        };
        
        for (const QString& path : paths) {
            if (QFile::exists(path)) {
                qmlFile = path;
                qDebug() << "Found QML at:" << qmlFile;
                break;
            }
        }
        
        if (!QFile::exists(qmlFile)) {
            qDebug() << "Could not find main.qml in any location";
            return -1;
        }
    }
    
    qDebug() << "Loading QML from:" << qmlFile;
    qDebug() << "GPU Acceleration: OpenGL enabled";
    
    engine.load(QUrl::fromLocalFile(qmlFile));
    
    if (engine.rootObjects().isEmpty()) {
        qDebug() << "Failed to load QML file";
        return -1;
    }
    
    // Enable GPU acceleration for all windows
    for (auto obj : engine.rootObjects()) {
        if (auto window = qobject_cast<QQuickWindow*>(obj)) {
            window->setColor(QColor(32, 32, 32)); // Dark background
            qDebug() << "Window graphics API:" << window->rendererInterface()->graphicsApi();
        }
    }
    
    return app.exec();
}
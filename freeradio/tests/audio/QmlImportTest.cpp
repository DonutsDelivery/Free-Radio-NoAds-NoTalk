#include <QtTest>
#include <QFile>
#include <QQmlComponent>
#include <QQmlEngine>
#include <memory>

class QmlImportTest : public QObject
{
    Q_OBJECT

private slots:
    void importsLoadableModule()
    {
        QQmlEngine engine;
        engine.addImportPath(QStringLiteral(FREERADIO_QML_IMPORT_PATH));
        QQmlComponent component(&engine);
        component.setData("import QtQml\nimport FreeRadio.Audio 1.0\nAudioEngine {}", QUrl());
        std::unique_ptr<QObject> object(component.create());
        QVERIFY2(object, qPrintable(component.errorString()));
    }

    void playbackControllerOwnsTwoAudioEngines()
    {
        QQmlEngine engine;
        engine.addImportPath(QStringLiteral(FREERADIO_QML_IMPORT_PATH));
        engine.addImportPath(QStringLiteral(FREERADIO_UI_PATH));
        QQmlComponent component(&engine,
            QUrl::fromLocalFile(QStringLiteral(FREERADIO_UI_PATH "/PlaybackController.qml")));
        std::unique_ptr<QObject> controller(component.create());
        QVERIFY2(controller, qPrintable(component.errorString()));
        QVERIFY(controller->property("main").value<QObject *>());
        QVERIFY(controller->property("preview").value<QObject *>());
        QCOMPARE(controller->property("playingState").toInt(), 3);
    }

    void productionPlaybackHasNoQtMultimediaFallback()
    {
        QFile mainContent(QStringLiteral(FREERADIO_UI_PATH "/MainContent.qml"));
        QVERIFY(mainContent.open(QIODevice::ReadOnly));
        const QByteArray qml = mainContent.readAll();
        QVERIFY(!qml.contains("QtMultimedia"));
        QVERIFY(!qml.contains("MediaPlayer"));
        QVERIFY(qml.contains("PlaybackController"));

        QFile cmake(QStringLiteral(FREERADIO_CMAKE_PATH));
        QVERIFY(cmake.open(QIODevice::ReadOnly));
        const QByteArray build = cmake.readAll();
        QVERIFY(!build.contains("Qt6::Multimedia"));
        QVERIFY(build.contains("freeradio_audio"));
    }
};

QTEST_GUILESS_MAIN(QmlImportTest)
#include "QmlImportTest.moc"

#include <QtTest>
#include <QDirIterator>
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

    void sharedUiIsMobilePortable()
    {
        // AC3: one shared UI supports desktop, Plasma, and mobile wrappers.
        QFile mainContent(QStringLiteral(FREERADIO_UI_PATH "/MainContent.qml"));
        QVERIFY(mainContent.open(QIODevice::ReadOnly));
        const QByteArray shared = mainContent.readAll();
        QVERIFY(!shared.contains("Kirigami.Icon"));
        QVERIFY(!shared.contains("org.kde.kirigami"));
        QVERIFY(shared.contains("PortableIcon"));
        QVERIFY(shared.contains("property bool isMobile"));
        QVERIFY(shared.contains("property real safeAreaLeft"));
        QVERIFY(shared.contains("touchTargetSize"));
        QVERIFY(shared.contains("portraitLayout"));
        QVERIFY(shared.contains("Qt.Key_Back"));
        QVERIFY(shared.contains("handleBackNavigation"));

        QFile standalone(QStringLiteral(FREERADIO_UI_PATH "/main_standalone.qml"));
        QVERIFY(standalone.open(QIODevice::ReadOnly));
        const QByteArray wrapper = standalone.readAll();
        QVERIFY(wrapper.contains("ApplicationWindow {"));
        QVERIFY(!wrapper.contains("Kirigami.ApplicationWindow"));
        QVERIFY(!wrapper.contains("org.kde.kirigami"));
        QVERIFY(wrapper.contains("SafeArea.margins"));
        QVERIFY(wrapper.contains("handleBackNavigation"));
    }

    void bufferingCommandsHonorUserIntent()
    {
        // AC4: Loading/Buffering are active states and must be cancellable.
        QFile controller(QStringLiteral(FREERADIO_UI_PATH "/PlaybackController.qml"));
        QVERIFY(controller.open(QIODevice::ReadOnly));
        const QByteArray playback = controller.readAll();
        QVERIFY(playback.contains("readonly property bool mainActive"));
        QVERIFY(playback.contains("playbackState === loadingState"));
        QVERIFY(playback.contains("playbackState === bufferingState"));
        QVERIFY(playback.contains("function suspendMain()"));
        QVERIFY(playback.contains("typeof mainEngine.seek"));
        QVERIFY(playback.contains("return mainEngine.seek(position) === true"));

        QFile mainContent(QStringLiteral(FREERADIO_UI_PATH "/MainContent.qml"));
        QVERIFY(mainContent.open(QIODevice::ReadOnly));
        const QByteArray shared = mainContent.readAll();
        QVERIFY(shared.count("if (playbackController.mainActive)") >= 2);
        QVERIFY(shared.contains("playbackController.suspendMain()"));
        QVERIFY(shared.contains("if (playbackController.seekMain(value))"));
        QVERIFY(shared.contains("This audiobook stream cannot resume"));
    }

    void productionPlaybackHasNoQtMultimediaFallback()
    {
        const QString repository = QStringLiteral(FREERADIO_REPOSITORY_PATH);
        QDirIterator files(repository,
            {QStringLiteral("*.qml"), QStringLiteral("CMakeLists*.txt")},
            QDir::Files, QDirIterator::Subdirectories);

        int scannedFiles = 0;
        while (files.hasNext()) {
            const QString path = files.next();
            const QString normalized = QDir::fromNativeSeparators(path);
            if (normalized.contains(QStringLiteral("/tests/"))
                || normalized.contains(QStringLiteral("/third_party/"))
                || normalized.contains(QStringLiteral("/aur-freeradio/"))
                || normalized.contains(QStringLiteral("/radcap-radio-widget/"))) {
                continue;
            }

            QFile file(path);
            QVERIFY2(file.open(QIODevice::ReadOnly), qPrintable(path));
            const QByteArray content = file.readAll();
            const QList<QByteArray> forbidden = {
                QByteArrayLiteral("QtMultimedia"),
                QByteArrayLiteral("MediaPlayer {"),
                QByteArrayLiteral("AudioOutput {"),
                QByteArrayLiteral("Qt6::Multimedia")
            };
            for (const QByteArray &token : forbidden) {
                QVERIFY2(!content.contains(token),
                    qPrintable(path + QStringLiteral(" contains forbidden playback token: ")
                        + QString::fromLatin1(token)));
            }
            ++scannedFiles;
        }
        QVERIFY(scannedFiles > 0);

        QFile mainContent(QStringLiteral(FREERADIO_UI_PATH "/MainContent.qml"));
        QVERIFY(mainContent.open(QIODevice::ReadOnly));
        QVERIFY(mainContent.readAll().contains("PlaybackController"));
    }
};

QTEST_GUILESS_MAIN(QmlImportTest)
#include "QmlImportTest.moc"

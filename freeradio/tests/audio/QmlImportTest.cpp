#include <QtTest>
#include <QQmlComponent>
#include <QQmlEngine>
#include <memory>

class QmlImportTest : public QObject
{
    Q_OBJECT

private slots:
    void importsLoadableModule()
    {
        // AC: @custom-inprocess-audio ac-5
        QQmlEngine engine;
        engine.addImportPath(QStringLiteral(FREERADIO_QML_IMPORT_PATH));
        QQmlComponent component(&engine);
        component.setData("import QtQml\nimport FreeRadio.Audio 1.0\nAudioEngine {}", QUrl());
        std::unique_ptr<QObject> object(component.create());
        QVERIFY2(object, qPrintable(component.errorString()));
    }
};

QTEST_GUILESS_MAIN(QmlImportTest)
#include "QmlImportTest.moc"

#include "AndroidMediaIntegration.h"

#ifdef Q_OS_ANDROID
#include <QJniObject>

AndroidMediaIntegration *AndroidMediaIntegration::s_instance = nullptr;

extern "C" JNIEXPORT void JNICALL
Java_org_freeradio_app_FreeRadioActivity_dispatchNativeCommand(JNIEnv *env,
                                                                jclass,
                                                                jstring command)
{
    if (!AndroidMediaIntegration::s_instance)
        return;

    const QString action = QJniObject(command).toString();
    AndroidMediaIntegration *integration = AndroidMediaIntegration::s_instance;
    QMetaObject::invokeMethod(integration, [integration, action] {
        if (action == QStringLiteral("play"))
            emit integration->playRequested();
        else if (action == QStringLiteral("pause"))
            emit integration->pauseRequested();
        else if (action == QStringLiteral("stop"))
            emit integration->stopRequested();
        else if (action == QStringLiteral("next"))
            emit integration->nextRequested();
        else if (action == QStringLiteral("previous"))
            emit integration->previousRequested();
    }, Qt::QueuedConnection);
}
#endif

AndroidMediaIntegration::AndroidMediaIntegration(QObject *parent)
    : QObject(parent)
{
#ifdef Q_OS_ANDROID
    s_instance = this;
#endif
}

AndroidMediaIntegration::~AndroidMediaIntegration()
{
#ifdef Q_OS_ANDROID
    if (s_instance == this)
        s_instance = nullptr;
#endif
}

void AndroidMediaIntegration::updatePlaybackState(bool playing,
                                                   const QString &station,
                                                   const QString &track)
{
#ifdef Q_OS_ANDROID
    QJniObject::callStaticMethod<void>(
        "org/freeradio/app/FreeRadioActivity",
        "updatePlaybackState",
        "(ZLjava/lang/String;Ljava/lang/String;)V",
        jboolean(playing),
        QJniObject::fromString(station).object<jstring>(),
        QJniObject::fromString(track).object<jstring>());
#else
    Q_UNUSED(playing)
    Q_UNUSED(station)
    Q_UNUSED(track)
#endif
}

void AndroidMediaIntegration::stopService()
{
#ifdef Q_OS_ANDROID
    QJniObject::callStaticMethod<void>("org/freeradio/app/FreeRadioActivity",
                                       "stopPlaybackService",
                                       "()V");
#endif
}

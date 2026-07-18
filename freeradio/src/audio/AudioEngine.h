#pragma once

#include <QObject>
#include <QUrl>
#include <QVariantList>
#include <QVector>
#include <QtQmlIntegration/qqmlintegration.h>
#include <memory>

class QNetworkAccessManager;
class QNetworkReply;
class QTimer;

namespace FreeRadio::Audio {

struct AudioWorker;
class SpectrumAnalyzer;

class AudioEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(PlaybackState playbackState READ playbackState NOTIFY playbackStateChanged)
    Q_PROPERTY(PlaybackError error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorChanged)
    Q_PROPERTY(bool buffering READ buffering NOTIFY bufferingChanged)
    Q_PROPERTY(float bufferingProgress READ bufferingProgress NOTIFY bufferingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(bool seekable READ seekable CONSTANT)
    Q_PROPERTY(QString icyTitle READ icyTitle NOTIFY icyMetadataChanged)
    Q_PROPERTY(QString icyName READ icyName NOTIFY icyMetadataChanged)
    Q_PROPERTY(QUrl icyUrl READ icyUrl NOTIFY icyMetadataChanged)
    Q_PROPERTY(QVariantList spectrum READ spectrum NOTIFY spectrumChanged)

public:
    enum PlaybackState { StoppedState, LoadingState, BufferingState, PlayingState, PausedState, ErrorState };
    Q_ENUM(PlaybackState)
    enum PlaybackError { NoError, NetworkError, PlaylistError, DecodeError, OutputError, UnsupportedError };
    Q_ENUM(PlaybackError)

    explicit AudioEngine(QObject *parent = nullptr);
    ~AudioEngine() override;

    QUrl source() const { return m_source; }
    void setSource(const QUrl &source);
    float volume() const { return m_volume; }
    void setVolume(float volume);
    PlaybackState playbackState() const { return m_state; }
    PlaybackError error() const { return m_error; }
    QString errorString() const { return m_errorString; }
    bool buffering() const { return m_state == BufferingState || m_state == LoadingState; }
    float bufferingProgress() const;
    qint64 position() const { return m_position; }
    qint64 duration() const { return m_duration; }
    bool seekable() const { return false; }
    QString icyTitle() const { return m_icyTitle; }
    QString icyName() const { return m_icyName; }
    QUrl icyUrl() const { return m_icyUrl; }
    QVariantList spectrum() const;

    Q_INVOKABLE void play();
    Q_INVOKABLE void play(const QUrl &source);
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE int spectrumBins() const { return m_spectrum.size(); }
    Q_INVOKABLE float spectrumBin(int index) const;

signals:
    void sourceChanged();
    void volumeChanged();
    void playbackStateChanged();
    void errorChanged();
    void bufferingChanged();
    void positionChanged();
    void durationChanged();
    void icyMetadataChanged();
    void spectrumChanged();

private:
    friend struct AudioWorker;
    struct Session;

    void beginRequest(const QUrl &url, quint64 generation, int playlistDepth = 0);
    void attachStreamReply(QNetworkReply *reply, quint64 generation);
    void drainNetworkReply(QNetworkReply *reply, quint64 generation);
    void startDecoder();
    void stopSession(bool advanceGeneration);
    void updatePlayback();
    void analyzeConsumedPcm();
    void tryNextPlaylist(quint64 generation, const QString &lastError);
    void setState(PlaybackState state);
    void fail(PlaybackError error, const QString &message);
    void decoderReady(quint64 generation, qint64 durationMs);
    void decoderEnded(quint64 generation, const QString &message, bool endOfStream);

    QUrl m_source;
    QUrl m_activeUrl;
    float m_volume = 1.0f;
    PlaybackState m_state = StoppedState;
    PlaybackError m_error = NoError;
    QString m_errorString;
    qint64 m_position = 0;
    qint64 m_duration = -1;
    QString m_icyTitle;
    QString m_icyName;
    QUrl m_icyUrl;
    QVector<float> m_spectrum;
    QVector<float> m_analysisWindow;
    QVector<float> m_analysisScratch;
    QVector<QUrl> m_playlistEntries;
    int m_playlistIndex = -1;
    QNetworkAccessManager *m_network = nullptr;
    QNetworkReply *m_reply = nullptr;
    QTimer *m_playbackTimer = nullptr;
    std::unique_ptr<SpectrumAnalyzer> m_analyzer;
    std::shared_ptr<Session> m_session;
    quint64 m_generation = 0;
    int m_reconnectAttempt = 0;
    bool m_networkBackpressured = false;
};

} // namespace FreeRadio::Audio

#define MINIAUDIO_IMPLEMENTATION
#define MA_NO_DECODING
#define MA_NO_ENCODING
#define MA_NO_RESOURCE_MANAGER

#include "AudioEngine.h"
#include "IcyDemuxer.h"
#include "NetworkBuffer.h"
#include "PcmRingBuffer.h"
#include "PlaylistParser.h"
#include "SpectrumAnalyzer.h"

#include <QMetaObject>
#include <QMutex>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QPointer>
#include <QTimer>
#include <QWaitCondition>
#include <algorithm>
#include <atomic>
#include <cstring>
#include <thread>
#include <vector>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/channel_layout.h>
#include <libavutil/error.h>
#include <libswresample/swresample.h>
}

namespace FreeRadio::Audio {
namespace {
constexpr int OutputRate = 48000;
constexpr int OutputChannels = 2;
constexpr std::size_t PcmCapacityFrames = OutputRate;
constexpr std::size_t AnalysisCapacityFrames = 4096;
constexpr std::size_t PrebufferFrames = OutputRate / 5;
constexpr std::size_t StallFrames = OutputRate / 50;

QString ffmpegError(int code)
{
    char text[AV_ERROR_MAX_STRING_SIZE] = {};
    av_strerror(code, text, sizeof(text));
    return QString::fromUtf8(text);
}
} // namespace

struct AudioEngine::Session
{
    explicit Session(AudioEngine *owner, quint64 value)
        : engine(owner), generation(value), requestedSource(owner->source()),
          pcm(PcmCapacityFrames, OutputChannels),
          consumed(AnalysisCapacityFrames, OutputChannels)
    {
    }

    static void playbackCallback(ma_device *device, void *output, const void *, ma_uint32 frames)
    {
        auto *session = static_cast<Session *>(device->pUserData);
        auto *samples = static_cast<float *>(output);
        const auto received = session ? session->pcm.read(samples, frames) : 0;
        if (session && received) {
            session->consumed.write(samples, received);
            session->playedFrames.fetch_add(received, std::memory_order_relaxed);
        }
        std::fill(samples + received * OutputChannels,
                  samples + static_cast<std::size_t>(frames) * OutputChannels, 0.0f);
    }

    QPointer<AudioEngine> engine;
    quint64 generation;
    QUrl requestedSource;
    NetworkBuffer network;
    PcmRingBuffer pcm;
    PcmRingBuffer consumed;
    IcyDemuxer icy;
    QMutex pcmWaitMutex;
    QWaitCondition pcmSpace;
    std::atomic<bool> cancelled{false};
    std::atomic<bool> paused{false};
    std::atomic<bool> decoderDone{false};
    std::atomic<qint64> playedFrames{0};
    ma_context context{};
    ma_device device{};
    bool contextInitialized = false;
    bool deviceInitialized = false;
    bool deviceStarted = false;
    bool replyFinished = false;
    bool finiteResponse = false;
};

struct DecoderResources
{
    AVFormatContext *format = nullptr;
    AVIOContext *avio = nullptr;
    AVCodecContext *codec = nullptr;
    SwrContext *resampler = nullptr;
    AVPacket *packet = nullptr;
    AVFrame *frame = nullptr;

    ~DecoderResources()
    {
        av_frame_free(&frame);
        av_packet_free(&packet);
        swr_free(&resampler);
        avcodec_free_context(&codec);
        if (format)
            avformat_close_input(&format);
        if (avio) {
            av_freep(&avio->buffer);
            avio_context_free(&avio);
        }
    }
};

static int readNetwork(void *opaque, uint8_t *buffer, int size)
{
    const int result = static_cast<NetworkBuffer *>(opaque)->read(buffer, size);
    if (result == NetworkBuffer::Cancelled)
        return AVERROR_EXIT;
    if (result == NetworkBuffer::EndOfStream)
        return AVERROR_EOF;
    return result;
}

static int interruptDecode(void *opaque)
{
    return static_cast<NetworkBuffer *>(opaque)->isCancelled() ? 1 : 0;
}

struct AudioWorker
{
    static void postDecoderReady(const std::shared_ptr<AudioEngine::Session> &session, qint64 duration);
    static void postDecoderEnded(const std::shared_ptr<AudioEngine::Session> &session,
                                 const QString &message, bool endOfStream);
    static void decodeStream(const std::shared_ptr<AudioEngine::Session> &session);
};

void AudioWorker::postDecoderReady(const std::shared_ptr<AudioEngine::Session> &session, qint64 duration)
{
    const QPointer<AudioEngine> engine = session->engine;
    if (!engine)
        return;
    QMetaObject::invokeMethod(engine.data(), [engine, generation = session->generation, duration] {
        if (engine)
            engine->decoderReady(generation, duration);
    }, Qt::QueuedConnection);
}

void AudioWorker::postDecoderEnded(const std::shared_ptr<AudioEngine::Session> &session,
                                   const QString &message, bool endOfStream)
{
    const QPointer<AudioEngine> engine = session->engine;
    if (!engine)
        return;
    QMetaObject::invokeMethod(engine.data(), [engine, generation = session->generation, message, endOfStream] {
        if (engine)
            engine->decoderEnded(generation, message, endOfStream);
    }, Qt::QueuedConnection);
}

void AudioWorker::decodeStream(const std::shared_ptr<AudioEngine::Session> &session)
{
    DecoderResources resources;
    resources.format = avformat_alloc_context();
    if (!resources.format) {
        postDecoderEnded(session, QStringLiteral("Could not allocate FFmpeg format context"), false);
        return;
    }
    auto *avioStorage = static_cast<unsigned char *>(av_malloc(32768));
    if (!avioStorage) {
        postDecoderEnded(session, QStringLiteral("Could not allocate FFmpeg input buffer"), false);
        return;
    }
    resources.avio = avio_alloc_context(avioStorage, 32768, 0, &session->network,
                                        readNetwork, nullptr, nullptr);
    if (!resources.avio) {
        av_free(avioStorage);
        postDecoderEnded(session, QStringLiteral("Could not create FFmpeg network input"), false);
        return;
    }
    resources.format->pb = resources.avio;
    resources.format->flags |= AVFMT_FLAG_CUSTOM_IO;
    resources.format->interrupt_callback = {interruptDecode, &session->network};

    int result = avformat_open_input(&resources.format, nullptr, nullptr, nullptr);
    if (result >= 0)
        result = avformat_find_stream_info(resources.format, nullptr);
    const int streamIndex = result >= 0
        ? av_find_best_stream(resources.format, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0) : result;
    if (result < 0 || streamIndex < 0) {
        if (!session->cancelled.load(std::memory_order_acquire))
            postDecoderEnded(session, QStringLiteral("Could not open audio stream: %1")
                                      .arg(ffmpegError(result < 0 ? result : streamIndex)), false);
        return;
    }

    const auto *parameters = resources.format->streams[streamIndex]->codecpar;
    const auto *decoder = avcodec_find_decoder(parameters->codec_id);
    if (!decoder) {
        postDecoderEnded(session, QStringLiteral("No FFmpeg decoder is available for this stream"), false);
        return;
    }
    resources.codec = avcodec_alloc_context3(decoder);
    if (!resources.codec || avcodec_parameters_to_context(resources.codec, parameters) < 0
        || avcodec_open2(resources.codec, decoder, nullptr) < 0) {
        postDecoderEnded(session, QStringLiteral("Could not initialize the FFmpeg audio decoder"), false);
        return;
    }

    AVChannelLayout outputLayout = AV_CHANNEL_LAYOUT_STEREO;
    result = swr_alloc_set_opts2(&resources.resampler, &outputLayout, AV_SAMPLE_FMT_FLT, OutputRate,
                                 &resources.codec->ch_layout, resources.codec->sample_fmt,
                                 resources.codec->sample_rate, 0, nullptr);
    av_channel_layout_uninit(&outputLayout);
    if (result < 0 || swr_init(resources.resampler) < 0) {
        postDecoderEnded(session, QStringLiteral("Could not initialize audio conversion"), false);
        return;
    }

    const qint64 duration = resources.format->duration > 0
        ? resources.format->duration / (AV_TIME_BASE / 1000) : -1;
    postDecoderReady(session, duration);
    resources.packet = av_packet_alloc();
    resources.frame = av_frame_alloc();
    if (!resources.packet || !resources.frame) {
        postDecoderEnded(session, QStringLiteral("Could not allocate FFmpeg decode frames"), false);
        return;
    }

    std::vector<float> converted;
    auto queueFrame = [&]() -> bool {
        const int capacity = swr_get_out_samples(resources.resampler, resources.frame->nb_samples);
        const auto required = static_cast<std::size_t>(capacity) * OutputChannels;
        if (converted.size() < required)
            converted.resize(required);
        uint8_t *outputData[] = {reinterpret_cast<uint8_t *>(converted.data())};
        const int outputFrames = swr_convert(resources.resampler, outputData, capacity,
                                             const_cast<const uint8_t **>(resources.frame->extended_data),
                                             resources.frame->nb_samples);
        if (outputFrames < 0)
            return false;
        std::size_t offset = 0;
        while (offset < static_cast<std::size_t>(outputFrames)
               && !session->cancelled.load(std::memory_order_acquire)) {
            offset += session->pcm.write(converted.data() + offset * OutputChannels,
                                         static_cast<std::size_t>(outputFrames) - offset);
            if (offset < static_cast<std::size_t>(outputFrames)) {
                QMutexLocker lock(&session->pcmWaitMutex);
                if (!session->cancelled.load(std::memory_order_relaxed))
                    session->pcmSpace.wait(&session->pcmWaitMutex);
            }
        }
        av_frame_unref(resources.frame);
        return true;
    };

    int readResult = 0;
    while (!session->cancelled.load(std::memory_order_acquire)
           && (readResult = av_read_frame(resources.format, resources.packet)) >= 0) {
        if (resources.packet->stream_index == streamIndex
            && avcodec_send_packet(resources.codec, resources.packet) >= 0) {
            while (avcodec_receive_frame(resources.codec, resources.frame) >= 0) {
                if (!queueFrame())
                    break;
            }
        }
        av_packet_unref(resources.packet);
    }

    if (!session->cancelled.load(std::memory_order_acquire) && readResult == AVERROR_EOF) {
        avcodec_send_packet(resources.codec, nullptr);
        while (avcodec_receive_frame(resources.codec, resources.frame) >= 0)
            queueFrame();
        while (swr_get_delay(resources.resampler, OutputRate) > 0) {
            const int capacity = swr_get_out_samples(resources.resampler, 0);
            const auto required = static_cast<std::size_t>(capacity) * OutputChannels;
            if (converted.size() < required)
                converted.resize(required);
            uint8_t *outputData[] = {reinterpret_cast<uint8_t *>(converted.data())};
            const int outputFrames = swr_convert(resources.resampler, outputData, capacity, nullptr, 0);
            if (outputFrames <= 0)
                break;
            std::size_t offset = 0;
            while (offset < static_cast<std::size_t>(outputFrames)
                   && !session->cancelled.load(std::memory_order_acquire)) {
                offset += session->pcm.write(converted.data() + offset * OutputChannels,
                                             static_cast<std::size_t>(outputFrames) - offset);
                if (offset < static_cast<std::size_t>(outputFrames)) {
                    QMutexLocker lock(&session->pcmWaitMutex);
                    if (!session->cancelled.load(std::memory_order_relaxed))
                        session->pcmSpace.wait(&session->pcmWaitMutex);
                }
            }
        }
        postDecoderEnded(session, {}, true);
    } else if (!session->cancelled.load(std::memory_order_acquire)) {
        postDecoderEnded(session, QStringLiteral("Audio stream read failed: %1").arg(ffmpegError(readResult)), false);
    }
}

AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent), m_spectrum(512, 0.0f), m_network(new QNetworkAccessManager(this)),
      m_playbackTimer(new QTimer(this)), m_analyzer(std::make_unique<SpectrumAnalyzer>(1024))
{
    m_analysisWindow.reserve(2048);
    m_analysisScratch.reserve(static_cast<qsizetype>(AnalysisCapacityFrames * OutputChannels));
    m_playbackTimer->setInterval(40);
    connect(m_playbackTimer, &QTimer::timeout, this, &AudioEngine::updatePlayback);
}

AudioEngine::~AudioEngine()
{
    stopSession(true);
}

float AudioEngine::bufferingProgress() const
{
    if (!m_session || m_state == LoadingState)
        return 0.0f;
    if (!buffering())
        return 1.0f;
    return std::clamp(static_cast<float>(m_session->pcm.availableFrames())
                      / static_cast<float>(PrebufferFrames), 0.0f, 1.0f);
}

QVariantList AudioEngine::spectrum() const
{
    QVariantList result;
    result.reserve(m_spectrum.size());
    for (float value : m_spectrum)
        result.append(value);
    return result;
}

float AudioEngine::spectrumBin(int index) const
{
    return index >= 0 && index < m_spectrum.size() ? m_spectrum[index] : 0.0f;
}

void AudioEngine::setSource(const QUrl &source)
{
    if (m_source == source)
        return;
    m_source = source;
    emit sourceChanged();
}

void AudioEngine::setVolume(float volume)
{
    volume = std::clamp(volume, 0.0f, 1.0f);
    if (qFuzzyCompare(m_volume, volume))
        return;
    m_volume = volume;
    if (m_session && m_session->deviceInitialized)
        ma_device_set_master_volume(&m_session->device, volume);
    emit volumeChanged();
}

void AudioEngine::play(const QUrl &source)
{
    setSource(source);
    play();
}

void AudioEngine::play()
{
    if (m_state == PausedState && m_session && m_session->requestedSource == m_source) {
        m_session->paused.store(false, std::memory_order_release);
        m_session->pcmSpace.wakeAll();
        setState(BufferingState);
        m_playbackTimer->start();
        return;
    }
    stopSession(true);
    if (!m_source.isValid() || m_source.isEmpty()
        || (m_source.scheme() != QStringLiteral("http") && m_source.scheme() != QStringLiteral("https"))) {
        fail(UnsupportedError, QStringLiteral("A valid HTTP or HTTPS audio source is required"));
        return;
    }
    m_error = NoError;
    m_errorString.clear();
    m_position = 0;
    m_duration = -1;
    m_activeUrl = m_source;
    m_playlistEntries.clear();
    m_playlistIndex = -1;
    m_reconnectAttempt = 0;
    m_icyTitle.clear();
    m_icyName.clear();
    m_icyUrl = QUrl();
    emit errorChanged();
    emit positionChanged();
    emit durationChanged();
    emit icyMetadataChanged();
    setState(LoadingState);
    beginRequest(m_source, m_generation);
}

void AudioEngine::pause()
{
    if ((m_state == PlayingState || m_state == BufferingState) && m_session) {
        m_session->paused.store(true, std::memory_order_release);
        if (m_session->deviceStarted) {
            ma_device_stop(&m_session->device);
            m_session->deviceStarted = false;
        }
        setState(PausedState);
    }
}

void AudioEngine::stop()
{
    stopSession(true);
    m_position = 0;
    m_spectrum.fill(0.0f);
    m_analysisWindow.clear();
    emit positionChanged();
    emit bufferingChanged();
    emit spectrumChanged();
    setState(StoppedState);
}

void AudioEngine::beginRequest(const QUrl &url, quint64 generation, int playlistDepth)
{
    if (generation != m_generation)
        return;
    if (playlistDepth > 4) {
        fail(PlaylistError, QStringLiteral("Playlist nesting limit exceeded"));
        return;
    }
    QNetworkRequest request(url);
    request.setRawHeader("Icy-MetaData", "1");
    request.setRawHeader("Accept", "audio/*, application/xspf+xml, */*;q=0.5");
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("FreeRadio/2.0"));
    request.setTransferTimeout(15000);
    request.setMaximumRedirectsAllowed(8);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    auto *reply = m_network->get(request);
    m_reply = reply;
    reply->setReadBufferSize(256 * 1024);
    struct RequestState { bool decided = false; bool playlist = false; QByteArray contentType; QByteArray data; };
    auto state = std::make_shared<RequestState>();
    auto decide = [this, reply, generation, state]() {
        if (generation != m_generation || state->decided)
            return;
        if (reply->attribute(QNetworkRequest::RedirectionTargetAttribute).isValid())
            return;
        state->contentType = reply->header(QNetworkRequest::ContentTypeHeader).toByteArray();
        state->playlist = PlaylistParser::isPlaylist(reply->url(), state->contentType);
        state->decided = true;
        if (!state->playlist)
            attachStreamReply(reply, generation);
    };
    connect(reply, &QNetworkReply::metaDataChanged, this, decide);
    connect(reply, &QIODevice::readyRead, this, [this, reply, generation, state, decide] {
        decide();
        if (generation != m_generation)
            return;
        if (state->playlist) {
            if (state->data.size() + reply->bytesAvailable() > 1024 * 1024) {
                fail(PlaylistError, QStringLiteral("Playlist is larger than 1 MiB"));
                return;
            }
            state->data += reply->readAll();
        } else {
            drainNetworkReply(reply, generation);
        }
    });
    connect(reply, &QNetworkReply::finished, this,
            [this, reply, generation, playlistDepth, state, decide] {
        if (generation != m_generation)
            return;
        decide();
        if (state->playlist) {
            state->data += reply->readAll();
            if (reply->error() != QNetworkReply::NoError) {
                tryNextPlaylist(generation, reply->errorString());
            } else if (PlaylistParser::isHls(state->data)) {
                fail(UnsupportedError, QStringLiteral("HLS manifests are recognized but not supported by the Qt Network stream feeder yet"));
            } else {
                m_playlistEntries = PlaylistParser::parse(state->data, reply->url(), state->contentType);
                m_playlistIndex = -1;
                if (m_playlistEntries.isEmpty())
                    fail(PlaylistError, QStringLiteral("Playlist contains no playable URLs"));
                else {
                    if (m_reply == reply)
                        m_reply = nullptr;
                    reply->deleteLater();
                    ++m_playlistIndex;
                    m_activeUrl = m_playlistEntries[m_playlistIndex];
                    beginRequest(m_activeUrl, generation, playlistDepth + 1);
                    return;
                }
            }
        } else if (m_session) {
            drainNetworkReply(reply, generation);
            m_session->replyFinished = true;
            if (reply->error() != QNetworkReply::NoError
                && reply->error() != QNetworkReply::OperationCanceledError)
                m_errorString = reply->errorString();
            if (reply->bytesAvailable() == 0) {
                m_session->network.finish();
                if (m_reply == reply)
                    m_reply = nullptr;
                reply->deleteLater();
            } else {
                m_networkBackpressured = true;
            }
            return;
        }
        if (m_reply == reply)
            m_reply = nullptr;
        reply->deleteLater();
    });
}

void AudioEngine::attachStreamReply(QNetworkReply *reply, quint64 generation)
{
    if (generation != m_generation || m_session)
        return;
    m_session = std::make_shared<Session>(this, generation);
    m_session->finiteResponse = reply->header(QNetworkRequest::ContentLengthHeader).toLongLong() > 0;
    m_activeUrl = reply->url();
    m_icyName = QString::fromUtf8(reply->rawHeader("icy-name"));
    m_icyUrl = QUrl(QString::fromUtf8(reply->rawHeader("icy-url")));
    m_session->icy.reset(reply->rawHeader("icy-metaint").toInt());
    emit icyMetadataChanged();
    setState(BufferingState);
    startDecoder();
    m_playbackTimer->start();
}

void AudioEngine::drainNetworkReply(QNetworkReply *reply, quint64 generation)
{
    if (generation != m_generation || !reply || !m_session)
        return;
    m_networkBackpressured = false;
    while (reply->bytesAvailable() > 0 && m_session->network.freeSpace() > 0) {
        const auto count = std::min<qint64>(reply->bytesAvailable(),
                                           static_cast<qint64>(m_session->network.freeSpace()));
        IcyDemuxer::Metadata metadata;
        const QByteArray audio = m_session->icy.process(reply->read(count), &metadata);
        if (!audio.isEmpty())
            m_session->network.append(audio.constData(), static_cast<std::size_t>(audio.size()));
        if (metadata.changed) {
            if (!metadata.title.isNull())
                m_icyTitle = metadata.title;
            if (!metadata.url.isEmpty())
                m_icyUrl = metadata.url;
            emit icyMetadataChanged();
        }
    }
    if (reply->bytesAvailable() > 0)
        m_networkBackpressured = true;
    if (m_session->replyFinished && reply->bytesAvailable() == 0) {
        m_session->network.finish();
        if (m_reply == reply)
            m_reply = nullptr;
        reply->deleteLater();
        m_networkBackpressured = false;
    }
}

void AudioEngine::startDecoder()
{
    const auto session = m_session;
    std::thread([session] { AudioWorker::decodeStream(session); }).detach();
}

void AudioEngine::stopSession(bool advanceGeneration)
{
    if (advanceGeneration)
        ++m_generation;
    m_playbackTimer->stop();
    m_networkBackpressured = false;
    if (m_reply) {
        disconnect(m_reply, nullptr, this, nullptr);
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
    }
    if (!m_session)
        return;
    auto session = std::move(m_session);
    session->engine.clear();
    session->cancelled.store(true, std::memory_order_release);
    session->network.cancel();
    session->pcmSpace.wakeAll();
    if (session->deviceInitialized) {
        if (session->deviceStarted)
            ma_device_stop(&session->device);
        ma_device_uninit(&session->device);
        session->deviceInitialized = false;
        session->deviceStarted = false;
    }
    if (session->contextInitialized) {
        ma_context_uninit(&session->context);
        session->contextInitialized = false;
    }
}

void AudioEngine::updatePlayback()
{
    if (!m_session)
        return;
    if (m_networkBackpressured && m_reply)
        drainNetworkReply(m_reply, m_generation);
    analyzeConsumedPcm();

    const auto frames = m_session->pcm.availableFrames();
    emit bufferingChanged();
    if (!m_session->paused.load(std::memory_order_acquire))
        m_session->pcmSpace.wakeAll();
    if (m_state == PausedState)
        return;

    if (m_session->deviceInitialized && !m_session->deviceStarted
        && (frames >= PrebufferFrames
            || (m_session->decoderDone.load(std::memory_order_acquire) && frames > 0))) {
        if (ma_device_start(&m_session->device) != MA_SUCCESS) {
            fail(OutputError, QStringLiteral("Could not start the miniaudio output device"));
            return;
        }
        m_session->deviceStarted = true;
        m_reconnectAttempt = 0;
        setState(PlayingState);
    } else if (m_session->deviceStarted && frames < StallFrames
               && !m_session->decoderDone.load(std::memory_order_acquire)) {
        ma_device_stop(&m_session->device);
        m_session->deviceStarted = false;
        setState(BufferingState);
    }

    const qint64 position = m_session->playedFrames.load(std::memory_order_relaxed) * 1000 / OutputRate;
    if (position != m_position) {
        m_position = position;
        emit positionChanged();
    }
    if (m_session->decoderDone.load(std::memory_order_acquire) && frames == 0) {
        if (!m_errorString.isEmpty()) {
            tryNextPlaylist(m_generation, m_errorString);
        } else if (m_duration < 0 && !m_session->finiteResponse) {
            const QUrl reconnectUrl = m_activeUrl;
            const int reconnectAttempt = ++m_reconnectAttempt;
            stopSession(true);
            if (reconnectAttempt > 3) {
                fail(NetworkError, QStringLiteral("Live stream disconnected repeatedly"));
                return;
            }
            setState(BufferingState);
            const quint64 generation = m_generation;
            QTimer::singleShot(std::min(reconnectAttempt * 500, 2000), this,
                               [this, generation, reconnectUrl] {
                if (generation == m_generation)
                    beginRequest(reconnectUrl, generation);
            });
        } else {
            stopSession(true);
            setState(StoppedState);
        }
    }
}

void AudioEngine::analyzeConsumedPcm()
{
    if (!m_session)
        return;
    const auto ready = m_session->consumed.availableFrames();
    if (!ready)
        return;
    m_analysisScratch.resize(static_cast<qsizetype>(ready * OutputChannels));
    const auto read = m_session->consumed.read(m_analysisScratch.data(), ready);
    const auto oldSize = m_analysisWindow.size();
    m_analysisWindow.resize(oldSize + static_cast<qsizetype>(read * OutputChannels));
    std::memcpy(m_analysisWindow.data() + oldSize, m_analysisScratch.constData(),
                read * OutputChannels * sizeof(float));
    constexpr qsizetype fftSamples = 1024 * OutputChannels;
    if (m_analysisWindow.size() < fftSamples)
        return;
    m_spectrum = m_analyzer->analyze(m_analysisWindow.constData(),
                                     static_cast<std::size_t>(m_analysisWindow.size() / OutputChannels),
                                     OutputChannels);
    if (m_analysisWindow.size() > fftSamples) {
        std::memmove(m_analysisWindow.data(),
                     m_analysisWindow.constData() + m_analysisWindow.size() - fftSamples,
                     fftSamples * sizeof(float));
        m_analysisWindow.resize(fftSamples);
    }
    emit spectrumChanged();
}

void AudioEngine::tryNextPlaylist(quint64 generation, const QString &lastError)
{
    if (generation != m_generation)
        return;
    if (m_playlistIndex + 1 < m_playlistEntries.size()) {
        const auto entries = m_playlistEntries;
        const int next = m_playlistIndex + 1;
        stopSession(true);
        m_playlistEntries = entries;
        m_playlistIndex = next;
        m_activeUrl = entries[next];
        m_errorString.clear();
        setState(LoadingState);
        beginRequest(m_activeUrl, m_generation, 1);
        return;
    }
    fail(NetworkError, lastError.isEmpty() ? QStringLiteral("All playlist entries failed") : lastError);
}

void AudioEngine::setState(PlaybackState state)
{
    if (m_state == state)
        return;
    const bool wasBuffering = buffering();
    m_state = state;
    emit playbackStateChanged();
    if (wasBuffering != buffering())
        emit bufferingChanged();
}

void AudioEngine::fail(PlaybackError error, const QString &message)
{
    m_error = error;
    m_errorString = message;
    emit errorChanged();
    setState(ErrorState);
    stopSession(true);
}

void AudioEngine::decoderReady(quint64 generation, qint64 durationMs)
{
    if (generation != m_generation || !m_session)
        return;
    m_duration = durationMs;
    emit durationChanged();
    ma_device_config config = ma_device_config_init(ma_device_type_playback);
    config.playback.format = ma_format_f32;
    config.playback.channels = OutputChannels;
    config.sampleRate = OutputRate;
    config.dataCallback = Session::playbackCallback;
    config.pUserData = m_session.get();
    ma_context *context = nullptr;
    if (qEnvironmentVariableIsSet("FREERADIO_AUDIO_NULL_DEVICE")) {
        const ma_backend backend = ma_backend_null;
        if (ma_context_init(&backend, 1, nullptr, &m_session->context) != MA_SUCCESS) {
            fail(OutputError, QStringLiteral("Could not initialize the miniaudio null context"));
            return;
        }
        m_session->contextInitialized = true;
        context = &m_session->context;
    }
    if (ma_device_init(context, &config, &m_session->device) != MA_SUCCESS) {
        fail(OutputError, QStringLiteral("Could not initialize the miniaudio output device"));
        return;
    }
    m_session->deviceInitialized = true;
    ma_device_set_master_volume(&m_session->device, m_volume);
}

void AudioEngine::decoderEnded(quint64 generation, const QString &message, bool endOfStream)
{
    if (generation != m_generation || !m_session)
        return;
    m_session->decoderDone.store(true, std::memory_order_release);
    if (!message.isEmpty()) {
        if (m_playlistIndex + 1 < m_playlistEntries.size())
            tryNextPlaylist(generation, message);
        else
            fail(DecodeError, message);
    } else if (!endOfStream) {
        fail(DecodeError, QStringLiteral("Audio decoder stopped unexpectedly"));
    }
}

} // namespace FreeRadio::Audio

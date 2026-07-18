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

#include <QCoreApplication>
#include <QMetaObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <algorithm>
#include <atomic>
#include <cerrno>
#include <condition_variable>
#include <cstdio>
#include <cstring>
#include <mutex>
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
constexpr qint64 StablePlaybackFrames = OutputRate * 10;

QString ffmpegError(int code)
{
    char text[AV_ERROR_MAX_STRING_SIZE] = {};
    av_strerror(code, text, sizeof(text));
    return QString::fromUtf8(text);
}

bool looksFiniteUrl(const QUrl &url)
{
    static const QStringList extensions = {
        QStringLiteral(".aac"), QStringLiteral(".flac"), QStringLiteral(".m4a"),
        QStringLiteral(".mp3"), QStringLiteral(".ogg"), QStringLiteral(".opus"),
        QStringLiteral(".wav"), QStringLiteral(".wma")
    };
    const QString path = url.path().toLower();
    return std::any_of(extensions.cbegin(), extensions.cend(),
                       [&path](const QString &extension) { return path.endsWith(extension); });
}
} // namespace

struct WorkerControl
{
    std::atomic<AudioEngine *> owner{nullptr};
};

struct AudioEngine::Session
{
    Session(const std::shared_ptr<WorkerControl> &workerControl, quint64 value,
            const QUrl &source, SourceIntent intent)
        : control(workerControl), generation(value), requestedSource(source), resolvedIntent(intent),
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

    std::shared_ptr<WorkerControl> control;
    quint64 generation;
    QUrl requestedSource;
    SourceIntent resolvedIntent;
    NetworkBuffer network;
    PcmRingBuffer pcm;
    PcmRingBuffer consumed;
    IcyDemuxer icy;
    std::mutex pcmWaitMutex;
    std::condition_variable pcmSpace;
    std::atomic<bool> cancelled{false};
    std::atomic<bool> paused{false};
    std::atomic<bool> decoderDone{false};
    std::atomic<bool> workerDone{false};
    std::atomic<qint64> playedFrames{0};
    std::atomic<bool> rangeSupported{false};
    std::atomic<bool> rangePending{false};
    qint64 seekTargetMs = -1;
    qint64 positionBaseMs = 0;
    std::thread worker;
    QString networkError;
    ma_context context{};
    ma_device device{};
    bool contextInitialized = false;
    bool deviceInitialized = false;
    bool deviceStarted = false;
    bool replyFinished = false;
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

struct AudioWorker
{
    static int readNetwork(void *opaque, uint8_t *buffer, int size);
    static int interruptDecode(void *opaque);
    static int64_t seekNetwork(void *opaque, int64_t offset, int whence);
    static void postRangeRequest(AudioEngine::Session *session, qint64 offset);
    static void postDecoderReady(const std::shared_ptr<AudioEngine::Session> &session, qint64 duration);
    static void postDecoderEnded(const std::shared_ptr<AudioEngine::Session> &session,
                                 const QString &message, bool endOfStream);
    static void decodeStream(const std::shared_ptr<AudioEngine::Session> &session);
};

int AudioWorker::readNetwork(void *opaque, uint8_t *buffer, int size)
{
    auto *session = static_cast<AudioEngine::Session *>(opaque);
    const int result = session->network.read(buffer, size);
    if (result == NetworkBuffer::Cancelled)
        return AVERROR_EXIT;
    if (result == NetworkBuffer::EndOfStream)
        return AVERROR_EOF;
    return result;
}

int AudioWorker::interruptDecode(void *opaque)
{
    return static_cast<AudioEngine::Session *>(opaque)->cancelled.load(std::memory_order_acquire) ? 1 : 0;
}

void AudioWorker::postRangeRequest(AudioEngine::Session *session, qint64 offset)
{
    const auto control = session->control;
    QMetaObject::invokeMethod(QCoreApplication::instance(), [control, generation = session->generation, offset] {
        if (auto *engine = control->owner.load(std::memory_order_acquire))
            engine->rangeRequested(generation, offset);
    }, Qt::QueuedConnection);
}

int64_t AudioWorker::seekNetwork(void *opaque, int64_t offset, int whence)
{
    auto *session = static_cast<AudioEngine::Session *>(opaque);
    if (whence & AVSEEK_SIZE)
        return session->network.totalSize();
    const int origin = whence & ~AVSEEK_FORCE;
    if (!session->rangeSupported.load(std::memory_order_acquire))
        return AVERROR(ENOSYS);
    int64_t target = offset;
    if (origin == SEEK_CUR)
        target += session->network.position();
    else if (origin == SEEK_END) {
        const auto size = session->network.totalSize();
        if (size < 0)
            return AVERROR(ENOSYS);
        target += size;
    } else if (origin != SEEK_SET) {
        return AVERROR(EINVAL);
    }
    const auto size = session->network.totalSize();
    if (target < 0 || (size >= 0 && target > size))
        return AVERROR(EINVAL);
    session->rangePending.store(true, std::memory_order_release);
    session->network.resetForRange(target);
    postRangeRequest(session, target);
    return target;
}

void AudioWorker::postDecoderReady(const std::shared_ptr<AudioEngine::Session> &session, qint64 duration)
{
    const auto control = session->control;
    QMetaObject::invokeMethod(QCoreApplication::instance(), [control, generation = session->generation, duration] {
        if (auto *engine = control->owner.load(std::memory_order_acquire))
            engine->decoderReady(generation, duration);
    }, Qt::QueuedConnection);
}

void AudioWorker::postDecoderEnded(const std::shared_ptr<AudioEngine::Session> &session,
                                   const QString &message, bool endOfStream)
{
    const auto control = session->control;
    QMetaObject::invokeMethod(QCoreApplication::instance(),
                              [control, generation = session->generation, message, endOfStream] {
        if (auto *engine = control->owner.load(std::memory_order_acquire))
            engine->decoderEnded(generation, message, endOfStream);
    }, Qt::QueuedConnection);
}

void AudioWorker::decodeStream(const std::shared_ptr<AudioEngine::Session> &session)
{
    struct CompletionGuard {
        AudioEngine::Session *session;
        ~CompletionGuard() { session->workerDone.store(true, std::memory_order_release); }
    } completion{session.get()};
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
    resources.avio = avio_alloc_context(avioStorage, 32768, 0, session.get(),
                                        readNetwork, nullptr, seekNetwork);
    if (!resources.avio) {
        av_free(avioStorage);
        postDecoderEnded(session, QStringLiteral("Could not create FFmpeg network input"), false);
        return;
    }
    resources.format->pb = resources.avio;
    resources.format->flags |= AVFMT_FLAG_CUSTOM_IO;
    resources.format->interrupt_callback = {interruptDecode, session.get()};

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
    if (session->seekTargetMs >= 0) {
        if (duration > 0)
            session->seekTargetMs = std::min(session->seekTargetMs, duration);
        const int64_t target = session->seekTargetMs * (AV_TIME_BASE / 1000);
        result = avformat_seek_file(resources.format, -1, INT64_MIN, target, INT64_MAX,
                                    AVSEEK_FLAG_BACKWARD);
        if (result < 0) {
            postDecoderEnded(session, QStringLiteral("Could not seek finite media: %1")
                                      .arg(ffmpegError(result)), false);
            return;
        }
        avcodec_flush_buffers(resources.codec);
        swr_close(resources.resampler);
        if (swr_init(resources.resampler) < 0) {
            postDecoderEnded(session, QStringLiteral("Could not reset audio conversion after seek"), false);
            return;
        }
        session->positionBaseMs = session->seekTargetMs;
    }
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
                std::unique_lock lock(session->pcmWaitMutex);
                if (!session->cancelled.load(std::memory_order_relaxed))
                    session->pcmSpace.wait(lock);
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
                    std::unique_lock lock(session->pcmWaitMutex);
                    if (!session->cancelled.load(std::memory_order_relaxed))
                        session->pcmSpace.wait(lock);
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
      m_playbackTimer(new QTimer(this)), m_reaperTimer(new QTimer(this)),
      m_workerControl(std::make_shared<WorkerControl>()),
      m_analyzer(std::make_unique<SpectrumAnalyzer>(1024))
{
    m_workerControl->owner.store(this, std::memory_order_release);
    m_analysisWindow.reserve(2048);
    m_analysisScratch.reserve(static_cast<qsizetype>(AnalysisCapacityFrames * OutputChannels));
    m_playbackTimer->setInterval(40);
    connect(m_playbackTimer, &QTimer::timeout, this, &AudioEngine::updatePlayback);
    m_reaperTimer->setInterval(25);
    connect(m_reaperTimer, &QTimer::timeout, this, [this] { reapWorkers(false); });
}

AudioEngine::~AudioEngine()
{
    m_workerControl->owner.store(nullptr, std::memory_order_release);
    stopSession(true);
    reapWorkers(true);
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

void AudioEngine::setSourceIntent(SourceIntent intent)
{
    if (m_sourceIntent == intent)
        return;
    m_sourceIntent = intent;
    emit sourceIntentChanged();
}

void AudioEngine::play(const QUrl &source)
{
    setSource(source);
    play();
}

void AudioEngine::play()
{
    if (m_state == PausedState && m_session && m_session->requestedSource == m_source) {
        m_pauseRequested = false;
        m_session->paused.store(false, std::memory_order_release);
        m_session->pcmSpace.notify_all();
        setState(BufferingState);
        m_playbackTimer->start();
        return;
    }
    const bool resumeCancelledLoading = m_state == PausedState && !m_session;
    stopSession(true);
    if (!resumeCancelledLoading)
        m_seekTargetMs = -1;
    m_pauseRequested = false;
    if (!m_source.isValid() || m_source.isEmpty()
        || (m_source.scheme() != QStringLiteral("http") && m_source.scheme() != QStringLiteral("https"))) {
        fail(UnsupportedError, QStringLiteral("A valid HTTP or HTTPS audio source is required"));
        return;
    }
    m_error = NoError;
    m_errorString.clear();
    m_position = m_seekTargetMs >= 0 ? m_seekTargetMs : 0;
    m_duration = -1;
    if (!resumeCancelledLoading && m_seekable) {
        m_seekable = false;
        emit seekableChanged();
    }
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
    if (m_state == LoadingState && !m_session) {
        m_pauseRequested = true;
        stopSession(true);
        setState(PausedState);
        return;
    }
    if ((m_state == PlayingState || m_state == BufferingState) && m_session) {
        m_pauseRequested = true;
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
    m_pauseRequested = false;
    m_seekTargetMs = -1;
    if (m_seekable) {
        m_seekable = false;
        emit seekableChanged();
    }
    m_position = 0;
    m_spectrum.fill(0.0f);
    m_analysisWindow.clear();
    emit positionChanged();
    emit bufferingChanged();
    emit spectrumChanged();
    setState(StoppedState);
}

void AudioEngine::seek(qint64 positionMs)
{
    const bool pendingFiniteSource = (m_state == LoadingState
                                      || (m_state == PausedState && !m_session))
        && (m_sourceIntent == FiniteIntent
            || (m_sourceIntent == AutoIntent && looksFiniteUrl(m_source)));
    if (!m_seekable && pendingFiniteSource) {
        m_seekTargetMs = std::max<qint64>(0, positionMs);
        m_position = m_seekTargetMs;
        emit positionChanged();
        return;
    }
    if (!m_seekable || m_activeUrl.isEmpty()) {
        m_error = UnsupportedError;
        m_errorString = QStringLiteral("The current source is not seekable");
        emit errorChanged();
        return;
    }
    const qint64 target = std::clamp(positionMs, qint64(0), std::max<qint64>(0, m_duration));
    const bool remainPaused = m_state == PausedState;
    const QUrl mediaUrl = m_activeUrl;
    stopSession(true);
    m_seekTargetMs = target;
    m_pauseRequested = remainPaused;
    m_analysisWindow.clear();
    m_spectrum.fill(0.0f);
    m_position = target;
    m_error = NoError;
    m_errorString.clear();
    emit positionChanged();
    emit spectrumChanged();
    emit errorChanged();
    setState(remainPaused ? PausedState : LoadingState);
    beginRequest(mediaUrl, m_generation);
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
                m_session->networkError = reply->errorString();
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

void AudioEngine::beginRangeRequest(const std::shared_ptr<Session> &session, qint64 offset)
{
    if (!session || session != m_session || session->generation != m_generation)
        return;
    if (m_reply) {
        disconnect(m_reply, nullptr, this, nullptr);
        m_reply->abort();
        m_reply->deleteLater();
    }
    session->replyFinished = false;
    QNetworkRequest request(m_activeUrl);
    request.setRawHeader("Range", QByteArray("bytes=") + QByteArray::number(offset) + '-');
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("FreeRadio/2.0"));
    request.setTransferTimeout(15000);
    request.setMaximumRedirectsAllowed(8);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    auto *reply = m_network->get(request);
    m_reply = reply;
    reply->setReadBufferSize(256 * 1024);
    auto responseAccepted = std::make_shared<bool>(false);
    auto validate = [session, reply, offset, responseAccepted]() {
        // A pending range after this response was accepted belongs to a newer FFmpeg seek.
        if (*responseAccepted)
            return !session->rangePending.load(std::memory_order_acquire);
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QByteArray contentRange = reply->rawHeader("Content-Range").trimmed();
        const int dash = contentRange.indexOf('-');
        bool offsetOk = false;
        const qint64 returnedOffset = contentRange.startsWith("bytes ") && dash > 6
            ? contentRange.mid(6, dash - 6).toLongLong(&offsetOk) : -1;
        if (status != 206 || !offsetOk || returnedOffset != offset) {
            session->networkError = QStringLiteral("HTTP range request at byte %1 returned an invalid partial response")
                                        .arg(offset);
            session->network.cancel();
            return false;
        }
        *responseAccepted = true;
        session->rangePending.store(false, std::memory_order_release);
        return true;
    };
    connect(reply, &QIODevice::readyRead, this, [this, session, reply, validate] {
        if (session != m_session || !validate())
            return;
        drainNetworkReply(reply, session->generation);
    });
    connect(reply, &QNetworkReply::finished, this, [this, session, reply, validate] {
        if (session != m_session)
            return;
        if (reply->error() != QNetworkReply::NoError) {
            session->networkError = reply->errorString();
            session->network.cancel();
        } else if (validate()) {
            drainNetworkReply(reply, session->generation);
            session->replyFinished = true;
            if (reply->bytesAvailable() == 0) {
                session->network.finish();
            } else {
                m_networkBackpressured = true;
                return;
            }
        }
        if (m_reply == reply)
            m_reply = nullptr;
        reply->deleteLater();
    });
}

void AudioEngine::rangeRequested(quint64 generation, qint64 offset)
{
    if (generation == m_generation && m_session)
        beginRangeRequest(m_session, offset);
}

void AudioEngine::attachStreamReply(QNetworkReply *reply, quint64 generation)
{
    if (generation != m_generation || m_session)
        return;
    SourceIntent intent = m_sourceIntent;
    if (intent == AutoIntent) {
        const bool hasIcyHeaders = !reply->rawHeader("icy-metaint").isEmpty()
            || !reply->rawHeader("icy-name").isEmpty();
        intent = hasIcyHeaders || !looksFiniteUrl(reply->url()) ? LiveIntent : FiniteIntent;
    }
    const qint64 contentLength = reply->header(QNetworkRequest::ContentLengthHeader).toLongLong();
    const bool supportsRanges = intent == FiniteIntent && contentLength > 0
        && reply->rawHeader("Accept-Ranges").toLower().contains("bytes");
    if (m_seekTargetMs >= 0 && !supportsRanges) {
        m_seekTargetMs = -1;
        fail(UnsupportedError, QStringLiteral("This finite source does not support HTTP byte ranges"));
        return;
    }
    m_session = std::make_shared<Session>(m_workerControl, generation, m_source, intent);
    m_session->rangeSupported.store(supportsRanges, std::memory_order_release);
    m_session->network.setTotalSize(contentLength);
    m_session->seekTargetMs = m_seekTargetMs;
    m_session->positionBaseMs = std::max<qint64>(0, m_seekTargetMs);
    m_session->paused.store(m_pauseRequested, std::memory_order_release);
    m_activeUrl = reply->url();
    m_icyName = QString::fromUtf8(reply->rawHeader("icy-name"));
    m_icyUrl = QUrl(QString::fromUtf8(reply->rawHeader("icy-url")));
    m_session->icy.reset(reply->rawHeader("icy-metaint").toInt());
    emit icyMetadataChanged();
    setState(m_pauseRequested ? PausedState : BufferingState);
    startDecoder();
    m_playbackTimer->start();
}

void AudioEngine::drainNetworkReply(QNetworkReply *reply, quint64 generation)
{
    if (generation != m_generation || !reply || !m_session
        || m_session->rangePending.load(std::memory_order_acquire))
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
            if (metadata.urlChanged)
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
    session->worker = std::thread([session] { AudioWorker::decodeStream(session); });
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
    session->cancelled.store(true, std::memory_order_release);
    session->network.cancel();
    session->pcmSpace.notify_all();
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
    m_retiredSessions.append(std::move(session));
    m_reaperTimer->start();
}

void AudioEngine::reapWorkers(bool waitForAll)
{
    for (qsizetype index = m_retiredSessions.size() - 1; index >= 0; --index) {
        const auto &session = m_retiredSessions[index];
        if (!waitForAll && !session->workerDone.load(std::memory_order_acquire))
            continue;
        if (session->worker.joinable())
            session->worker.join();
        m_retiredSessions.removeAt(index);
    }
    if (m_retiredSessions.isEmpty())
        m_reaperTimer->stop();
}

void AudioEngine::updatePlayback()
{
    const auto session = m_session;
    if (!session)
        return;
    if (m_networkBackpressured && m_reply)
        drainNetworkReply(m_reply, m_generation);
    if (session != m_session)
        return;
    analyzeConsumedPcm();
    if (session != m_session)
        return;

    const auto frames = session->pcm.availableFrames();
    emit bufferingChanged();
    if (session != m_session)
        return;
    if (!session->paused.load(std::memory_order_acquire))
        session->pcmSpace.notify_all();
    if (m_state == PausedState)
        return;

    if (session->deviceInitialized && !session->deviceStarted
        && (frames >= PrebufferFrames
            || (session->decoderDone.load(std::memory_order_acquire) && frames > 0))) {
        if (ma_device_start(&session->device) != MA_SUCCESS) {
            fail(OutputError, QStringLiteral("Could not start the miniaudio output device"));
            return;
        }
        session->deviceStarted = true;
        setState(PlayingState);
        if (session != m_session)
            return;
    } else if (session->deviceStarted && frames < StallFrames
               && !session->decoderDone.load(std::memory_order_acquire)) {
        ma_device_stop(&session->device);
        session->deviceStarted = false;
        setState(BufferingState);
        if (session != m_session)
            return;
    }

    const qint64 playedFrames = session->playedFrames.load(std::memory_order_relaxed);
    if (playedFrames >= StablePlaybackFrames)
        m_reconnectAttempt = 0;
    const qint64 position = session->positionBaseMs + playedFrames * 1000 / OutputRate;
    if (position != m_position) {
        m_position = position;
        emit positionChanged();
        if (session != m_session)
            return;
    }
    if (session->decoderDone.load(std::memory_order_acquire) && frames == 0) {
        const QString networkError = session->networkError;
        const bool shouldReconnect = session->resolvedIntent == LiveIntent;
        if (!networkError.isEmpty() && !shouldReconnect) {
            tryNextPlaylist(m_generation, networkError);
        } else if (shouldReconnect) {
            const QUrl reconnectUrl = m_activeUrl;
            const int reconnectAttempt = ++m_reconnectAttempt;
            stopSession(true);
            if (reconnectAttempt > 3) {
                fail(NetworkError, networkError.isEmpty()
                         ? QStringLiteral("Live stream disconnected repeatedly")
                         : QStringLiteral("Live stream disconnected repeatedly: %1").arg(networkError));
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
    const bool canSeek = durationMs > 0
        && m_session->rangeSupported.load(std::memory_order_acquire);
    if (m_seekable != canSeek) {
        m_seekable = canSeek;
        emit seekableChanged();
    }
    if (m_session->seekTargetMs >= 0 && m_position != m_session->positionBaseMs) {
        m_position = m_session->positionBaseMs;
        emit positionChanged();
    }
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
        if (m_session->resolvedIntent == LiveIntent) {
            m_session->networkError = message;
        } else if (!m_session->networkError.isEmpty()) {
            tryNextPlaylist(generation, m_session->networkError);
        } else if (m_playlistIndex + 1 < m_playlistEntries.size()) {
            tryNextPlaylist(generation, message);
        } else {
            fail(DecodeError, message);
        }
    } else if (!endOfStream) {
        fail(DecodeError, QStringLiteral("Audio decoder stopped unexpectedly"));
    }
}

} // namespace FreeRadio::Audio

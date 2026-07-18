#include <QtTest>
#include <QDataStream>
#include <QTcpServer>
#include <QTcpSocket>
#include <cmath>
#include <future>

#include "audio/AudioEngine.h"
#include "audio/IcyDemuxer.h"
#include "audio/NetworkBuffer.h"
#include "audio/PcmRingBuffer.h"
#include "audio/PlaylistParser.h"
#include "audio/SpectrumAnalyzer.h"

using namespace FreeRadio::Audio;

namespace {
constexpr double Pi = 3.14159265358979323846;

QByteArray wavFixture()
{
    constexpr int sampleRate = 48000;
    constexpr int frames = sampleRate / 2;
    QByteArray pcm(frames * 2 * 2, Qt::Uninitialized);
    auto *samples = reinterpret_cast<qint16 *>(pcm.data());
    for (int i = 0; i < frames; ++i) {
        const auto value = static_cast<qint16>(std::sin(2.0 * Pi * 440.0 * i / sampleRate) * 12000);
        samples[i * 2] = value;
        samples[i * 2 + 1] = value;
    }
    QByteArray wav;
    QDataStream stream(&wav, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    stream.writeRawData("RIFF", 4);
    stream << quint32(36 + pcm.size());
    stream.writeRawData("WAVEfmt ", 8);
    stream << quint32(16) << quint16(1) << quint16(2) << quint32(sampleRate)
           << quint32(sampleRate * 4) << quint16(4) << quint16(16);
    stream.writeRawData("data", 4);
    stream << quint32(pcm.size());
    stream.writeRawData(pcm.constData(), pcm.size());
    return wav;
}
} // namespace

class AudioCoreTest : public QObject
{
    Q_OBJECT

private slots:
    void parsesM3u()
    {
        // AC: @custom-inprocess-audio ac-2
        const auto urls = PlaylistParser::parse("#EXTM3U\nstream.mp3\nfile:///tmp/audio.mp3\njavascript:bad\nhttps://example.org/live\n",
                                                QUrl("https://radio.test/lists/list.m3u"));
        QCOMPARE(urls.size(), 2);
        QCOMPARE(urls[0], QUrl("https://radio.test/lists/stream.mp3"));
        QCOMPARE(urls[1], QUrl("https://example.org/live"));
    }

    void parsesPls()
    {
        // AC: @custom-inprocess-audio ac-2
        const auto urls = PlaylistParser::parse("[playlist]\nFile2=http://two.test/live\nFile1=http://one.test/live\n",
                                                QUrl("http://radio.test/list.pls"));
        QCOMPARE(urls.size(), 2);
        QCOMPARE(urls[0], QUrl("http://two.test/live"));
    }

    void parsesXspfAndRecognizesHls()
    {
        // AC: @custom-inprocess-audio ac-2
        const QByteArray xml = "<?xml version='1.0'?><playlist><trackList><track>"
                               "<location>https://radio.test/live.mp3</location>"
                               "</track></trackList></playlist>";
        QCOMPARE(PlaylistParser::parse(xml, QUrl("https://radio.test/list.xspf")),
                 QVector<QUrl>{QUrl("https://radio.test/live.mp3")});
        QVERIFY(PlaylistParser::isHls("#EXTM3U\n#EXT-X-TARGETDURATION:6\nsegment.aac\n"));
        QVERIFY(!PlaylistParser::isHls("#EXTM3U\nhttps://radio.test/live\n"));
    }

    void icyMetadataSurvivesChunkBoundaries()
    {
        // AC: @custom-inprocess-audio ac-2
        IcyDemuxer demuxer;
        demuxer.reset(4);
        IcyDemuxer::Metadata metadata;
        QByteArray audio;
        audio += demuxer.process(QByteArray("AB", 2), &metadata);
        QByteArray second("CD", 2);
        second.append(char(1));
        second += "StreamT";
        audio += demuxer.process(second, &metadata);
        audio += demuxer.process("itle='X';EFGH", &metadata);
        QCOMPARE(audio, QByteArray("ABCDEFGH"));
        QVERIFY(metadata.changed);
        QCOMPARE(metadata.title, QStringLiteral("X"));
    }

    void icyUrlCanBeCleared()
    {
        // AC: @custom-inprocess-audio ac-2
        IcyDemuxer demuxer;
        demuxer.reset(1);
        IcyDemuxer::Metadata metadata;
        QByteArray first("A", 1);
        first.append(char(2));
        first += QByteArray("StreamUrl='https://x';").leftJustified(32, '\0');
        demuxer.process(first, &metadata);
        QVERIFY(metadata.urlChanged);
        QCOMPARE(metadata.url, QUrl("https://x"));

        metadata = {};
        QByteArray second("B", 1);
        second.append(char(1));
        second += QByteArray("StreamUrl='';").leftJustified(16, '\0');
        demuxer.process(second, &metadata);
        QVERIFY(metadata.urlChanged);
        QVERIFY(metadata.url.isEmpty());
    }

    void miniaudioRingWrapsWithoutOverwriting()
    {
        // AC: @custom-inprocess-audio ac-3
        PcmRingBuffer ring(5, 1);
        QVERIFY(ring.isValid());
        const float first[] = {1, 2, 3, 4};
        QCOMPARE(ring.write(first, 4), std::size_t(4));
        float output[5] = {};
        QCOMPARE(ring.read(output, 2), std::size_t(2));
        const float second[] = {5, 6, 7, 8};
        QCOMPARE(ring.write(second, 4), std::size_t(3));
        QCOMPARE(ring.read(output, 5), std::size_t(5));
        QCOMPARE(QVector<float>(output, output + 5), QVector<float>({3, 4, 5, 6, 7}));
    }

    void fftFindsSinePeak()
    {
        // AC: @custom-inprocess-audio ac-4
        constexpr int size = 1024;
        constexpr int expectedBin = 32;
        QVector<float> samples(size * 2);
        for (int i = 0; i < size; ++i) {
            const float value = std::sin(2.0 * Pi * expectedBin * i / size);
            samples[i * 2] = value;
            samples[i * 2 + 1] = value;
        }
        SpectrumAnalyzer analyzer(size);
        const auto bins = analyzer.analyze(samples.constData(), size, 2);
        const auto peak = std::distance(bins.cbegin(), std::max_element(bins.cbegin(), bins.cend()));
        QCOMPARE(peak, qsizetype(expectedBin));
        QVERIFY(bins[peak] > 0.15f);
    }

    void cancellationUnblocksNetworkRead()
    {
        // AC: @custom-inprocess-audio ac-1
        NetworkBuffer buffer(64);
        auto pending = std::async(std::launch::async, [&buffer] {
            unsigned char byte = 0;
            return buffer.read(&byte, 1);
        });
        QTest::qSleep(30);
        buffer.cancel();
        QVERIFY(pending.wait_for(std::chrono::seconds(1)) == std::future_status::ready);
        QCOMPARE(pending.get(), NetworkBuffer::Cancelled);
    }

    void stopCancelsPendingRequest()
    {
        // AC: @custom-inprocess-audio ac-1
        QTcpServer server;
        QVERIFY(server.listen(QHostAddress::LocalHost));
        AudioEngine engine;
        engine.play(QUrl(QStringLiteral("http://127.0.0.1:%1/live").arg(server.serverPort())));
        QTRY_VERIFY_WITH_TIMEOUT(server.hasPendingConnections(), 1000);
        std::unique_ptr<QTcpSocket> connection(server.nextPendingConnection());
        QTRY_VERIFY_WITH_TIMEOUT(connection->bytesAvailable() > 0, 1000);
        connection->readAll();
        engine.stop();
        QCOMPARE(engine.playbackState(), AudioEngine::StoppedState);
        QTest::qWait(50);
        QCOMPARE(engine.playbackState(), AudioEngine::StoppedState);
    }

    void invalidReplacementCancelsOldSource()
    {
        // AC: @custom-inprocess-audio ac-1
        QTcpServer server;
        QVERIFY(server.listen(QHostAddress::LocalHost));
        AudioEngine engine;
        engine.play(QUrl(QStringLiteral("http://127.0.0.1:%1/live").arg(server.serverPort())));
        QTRY_VERIFY_WITH_TIMEOUT(server.hasPendingConnections(), 1000);
        std::unique_ptr<QTcpSocket> connection(server.nextPendingConnection());
        QTRY_VERIFY_WITH_TIMEOUT(connection->bytesAvailable() > 0, 1000);
        connection->readAll();
        engine.play(QUrl());
        QCOMPARE(engine.playbackState(), AudioEngine::ErrorState);
        QCOMPARE(engine.error(), AudioEngine::UnsupportedError);
        QTRY_VERIFY_WITH_TIMEOUT(connection->state() == QAbstractSocket::UnconnectedState, 1000);
    }

    void repeatedShortLiveStreamHitsReconnectCap()
    {
        // AC: @custom-inprocess-audio ac-1
        // AC: @custom-inprocess-audio ac-5
        qputenv("FREERADIO_AUDIO_NULL_DEVICE", "1");
        QTcpServer server;
        QVERIFY(server.listen(QHostAddress::LocalHost));
        const QByteArray fixture = wavFixture();
        int requests = 0;
        connect(&server, &QTcpServer::newConnection, this, [&] {
            while (server.hasPendingConnections()) {
                auto *socket = server.nextPendingConnection();
                auto respond = [&, socket] {
                    if (socket->bytesAvailable() == 0)
                        return;
                    socket->readAll();
                    ++requests;
                    socket->write("HTTP/1.1 200 OK\r\nContent-Type: audio/wav\r\nContent-Length: ");
                    socket->write(QByteArray::number(fixture.size()));
                    socket->write("\r\nConnection: close\r\n\r\n");
                    socket->write(requests == 2 ? fixture.left(fixture.size() / 2) : fixture);
                    socket->disconnectFromHost();
                };
                connect(socket, &QTcpSocket::readyRead, socket, respond);
                respond();
            }
        });

        AudioEngine engine;
        engine.setSourceIntent(AudioEngine::LiveIntent);
        engine.play(QUrl(QStringLiteral("http://127.0.0.1:%1/live").arg(server.serverPort())));
        QTRY_COMPARE_WITH_TIMEOUT(engine.playbackState(), AudioEngine::ErrorState, 10000);
        QCOMPARE(engine.error(), AudioEngine::NetworkError);
        QCOMPARE(requests, 4);
        qunsetenv("FREERADIO_AUDIO_NULL_DEVICE");
    }

    void rapidSwitchAndDestroyAfterDecodeStarts()
    {
        // AC: @custom-inprocess-audio ac-1
        qputenv("FREERADIO_AUDIO_NULL_DEVICE", "1");
        QTcpServer server;
        QVERIFY(server.listen(QHostAddress::LocalHost));
        const QByteArray fixture = wavFixture();
        connect(&server, &QTcpServer::newConnection, this, [&] {
            while (server.hasPendingConnections()) {
                auto *socket = server.nextPendingConnection();
                auto respond = [&, socket] {
                    if (socket->bytesAvailable() == 0)
                        return;
                    socket->readAll();
                    socket->write("HTTP/1.1 200 OK\r\nContent-Type: audio/wav\r\nContent-Length: ");
                    socket->write(QByteArray::number(fixture.size()));
                    socket->write("\r\nConnection: close\r\n\r\n");
                    socket->write(fixture);
                    socket->disconnectFromHost();
                };
                connect(socket, &QTcpSocket::readyRead, socket, respond);
                respond();
            }
        });
        auto engine = std::make_unique<AudioEngine>();
        engine->setSourceIntent(AudioEngine::FiniteIntent);
        const QUrl url(QStringLiteral("http://127.0.0.1:%1/fixture.wav").arg(server.serverPort()));
        for (int iteration = 0; iteration < 5; ++iteration) {
            engine->play(url);
            QTRY_COMPARE_WITH_TIMEOUT(engine->playbackState(), AudioEngine::PlayingState, 2000);
        }
        engine.reset();
        qunsetenv("FREERADIO_AUDIO_NULL_DEVICE");
    }

    void localHttpDecodeBuffersPlaysAndEnds()
    {
        // AC: @custom-inprocess-audio ac-1
        // AC: @custom-inprocess-audio ac-5
        qputenv("FREERADIO_AUDIO_NULL_DEVICE", "1");
        QTcpServer server;
        QVERIFY(server.listen(QHostAddress::LocalHost));
        AudioEngine engine;
        engine.play(QUrl(QStringLiteral("http://127.0.0.1:%1/fixture.wav").arg(server.serverPort())));
        QTRY_VERIFY_WITH_TIMEOUT(server.hasPendingConnections(), 1000);
        std::unique_ptr<QTcpSocket> connection(server.nextPendingConnection());
        QTRY_VERIFY_WITH_TIMEOUT(connection->bytesAvailable() > 0, 1000);
        connection->readAll();
        const QByteArray fixture = wavFixture();
        connection->write("HTTP/1.1 200 OK\r\nContent-Type: audio/wav\r\nTransfer-Encoding: chunked");
        connection->write("\r\nConnection: close\r\n\r\n");
        connection->write(QByteArray::number(fixture.size(), 16));
        connection->write("\r\n");
        connection->write(fixture);
        connection->write("\r\n0\r\n\r\n");
        connection->flush();
        connection->disconnectFromHost();
        QTRY_COMPARE_WITH_TIMEOUT(engine.playbackState(), AudioEngine::PlayingState, 3000);
        engine.pause();
        QCOMPARE(engine.playbackState(), AudioEngine::PausedState);
        const qint64 pausedPosition = engine.position();
        QTest::qWait(80);
        QCOMPARE(engine.position(), pausedPosition);
        engine.play();
        QTRY_COMPARE_WITH_TIMEOUT(engine.playbackState(), AudioEngine::PlayingState, 1000);
        QTRY_COMPARE_WITH_TIMEOUT(engine.playbackState(), AudioEngine::StoppedState, 3000);
        QVERIFY(engine.position() >= 400);
        QVERIFY(engine.spectrum().size() == 512);
        qunsetenv("FREERADIO_AUDIO_NULL_DEVICE");
    }

};

QTEST_GUILESS_MAIN(AudioCoreTest)
#include "AudioCoreTest.moc"

#pragma once

#include <QByteArray>
#include <QUrl>
#include <QVector>

namespace FreeRadio::Audio {

class PlaylistParser
{
public:
    static bool isPlaylist(const QUrl &url, const QByteArray &contentType);
    static bool isHls(const QByteArray &data);
    static QVector<QUrl> parse(const QByteArray &data, const QUrl &baseUrl,
                               const QByteArray &contentType = {});
};

} // namespace FreeRadio::Audio

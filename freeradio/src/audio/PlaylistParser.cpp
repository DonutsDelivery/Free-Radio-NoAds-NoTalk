#include "PlaylistParser.h"

#include <QDomDocument>
#include <QRegularExpression>
#include <QStringList>

namespace FreeRadio::Audio {
namespace {
QUrl resolvedUrl(const QString &text, const QUrl &base)
{
    const QUrl candidate(text.trimmed());
    return candidate.isRelative() ? base.resolved(candidate) : candidate;
}

void appendIfValid(QVector<QUrl> &result, const QString &text, const QUrl &base)
{
    const auto url = resolvedUrl(text, base);
    if (url.isValid() && !url.isEmpty())
        result.append(url);
}
} // namespace

bool PlaylistParser::isPlaylist(const QUrl &url, const QByteArray &contentType)
{
    const auto path = url.path().toLower();
    const auto type = contentType.toLower().split(';').first().trimmed();
    return path.endsWith(".m3u") || path.endsWith(".m3u8") || path.endsWith(".pls")
        || path.endsWith(".xspf") || type == "audio/x-mpegurl"
        || type == "audio/mpegurl" || type == "application/vnd.apple.mpegurl"
        || type == "audio/x-scpls" || type == "application/xspf+xml";
}

bool PlaylistParser::isHls(const QByteArray &data)
{
    return data.toUpper().contains("#EXT-X-");
}

QVector<QUrl> PlaylistParser::parse(const QByteArray &data, const QUrl &baseUrl,
                                    const QByteArray &contentType)
{
    QVector<QUrl> result;
    const auto path = baseUrl.path().toLower();
    const auto type = contentType.toLower();

    if (path.endsWith(".xspf") || type.contains("xspf") || data.trimmed().startsWith("<?xml")) {
        QDomDocument document;
        if (!document.setContent(data))
            return result;
        const auto nodes = document.elementsByTagName("location");
        for (int i = 0; i < nodes.count(); ++i)
            appendIfValid(result, nodes.item(i).toElement().text(), baseUrl);
        return result;
    }

    const QString text = QString::fromUtf8(data);
    if (path.endsWith(".pls") || type.contains("scpls")
        || text.trimmed().startsWith("[playlist]", Qt::CaseInsensitive)) {
        static const QRegularExpression entry(QStringLiteral(R"(^\s*File\d+\s*=\s*(.+)\s*$)"),
                                               QRegularExpression::CaseInsensitiveOption);
        for (const auto &line : text.split(QRegularExpression("[\r\n]+"))) {
            const auto match = entry.match(line);
            if (match.hasMatch())
                appendIfValid(result, match.captured(1), baseUrl);
        }
        return result;
    }

    for (const auto &line : text.split(QRegularExpression("[\r\n]+"))) {
        const auto trimmed = line.trimmed();
        if (!trimmed.isEmpty() && !trimmed.startsWith('#'))
            appendIfValid(result, trimmed, baseUrl);
    }
    return result;
}

} // namespace FreeRadio::Audio

#include "IcyDemuxer.h"

#include <QRegularExpression>
#include <algorithm>

namespace FreeRadio::Audio {

void IcyDemuxer::reset(int metadataInterval)
{
    m_interval = std::max(0, metadataInterval);
    m_audioRemaining = m_interval;
    m_metadataRemaining = -1;
    m_metadata.clear();
    m_title.clear();
    m_url = QUrl();
}

QByteArray IcyDemuxer::process(const QByteArray &data, Metadata *metadata)
{
    if (m_interval == 0)
        return data;
    QByteArray audio;
    audio.reserve(data.size());
    int offset = 0;
    while (offset < data.size()) {
        if (m_audioRemaining > 0) {
            const int count = std::min(m_audioRemaining, static_cast<int>(data.size()) - offset);
            audio.append(data.constData() + offset, count);
            offset += count;
            m_audioRemaining -= count;
        } else if (m_metadataRemaining < 0) {
            m_metadataRemaining = static_cast<unsigned char>(data[offset++]) * 16;
            m_metadata.clear();
            if (m_metadataRemaining == 0) {
                m_metadataRemaining = -1;
                m_audioRemaining = m_interval;
            }
        } else {
            const int count = std::min(m_metadataRemaining, static_cast<int>(data.size()) - offset);
            m_metadata.append(data.constData() + offset, count);
            offset += count;
            m_metadataRemaining -= count;
            if (m_metadataRemaining == 0) {
                parseMetadata(metadata);
                m_metadataRemaining = -1;
                m_audioRemaining = m_interval;
            }
        }
    }
    return audio;
}

void IcyDemuxer::parseMetadata(Metadata *metadata)
{
    if (!metadata)
        return;
    static const QRegularExpression titlePattern(QStringLiteral("StreamTitle='([^']*)'"),
                                                  QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression urlPattern(QStringLiteral("StreamUrl='([^']*)'"),
                                                QRegularExpression::CaseInsensitiveOption);
    const QString text = QString::fromUtf8(m_metadata).remove(QChar('\0'));
    const auto titleMatch = titlePattern.match(text);
    const auto urlMatch = urlPattern.match(text);
    if (titleMatch.hasMatch() && m_title != titleMatch.captured(1)) {
        m_title = titleMatch.captured(1);
        metadata->title = m_title;
        metadata->changed = true;
    }
    const QUrl newUrl = urlMatch.hasMatch() ? QUrl(urlMatch.captured(1)) : m_url;
    if (newUrl != m_url) {
        m_url = newUrl;
        metadata->url = m_url;
        metadata->urlChanged = true;
        metadata->changed = true;
    }
}

} // namespace FreeRadio::Audio

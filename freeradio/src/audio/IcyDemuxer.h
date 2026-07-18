#pragma once

#include <QByteArray>
#include <QString>
#include <QUrl>

namespace FreeRadio::Audio {

class IcyDemuxer
{
public:
    struct Metadata {
        QString title;
        QUrl url;
        bool changed = false;
        bool urlChanged = false;
    };

    void reset(int metadataInterval);
    QByteArray process(const QByteArray &data, Metadata *metadata = nullptr);

private:
    void parseMetadata(Metadata *metadata);

    int m_interval = 0;
    int m_audioRemaining = 0;
    int m_metadataRemaining = -1;
    QByteArray m_metadata;
    QString m_title;
    QUrl m_url;
};

} // namespace FreeRadio::Audio

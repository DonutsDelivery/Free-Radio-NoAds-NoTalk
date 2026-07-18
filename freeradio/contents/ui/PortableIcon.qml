import QtQuick
import QtQuick.Controls

// Theme-independent transport icon rendered from glyphs bundled with the QML.
// This avoids desktop icon-theme and Kirigami dependencies on mobile.
Item {
    id: icon

    property string source: ""
    property color color: palette.buttonText
    implicitWidth: 24
    implicitHeight: 24

    Label {
        anchors.fill: parent
        text: {
            switch (icon.source) {
            case "media-playback-start": return "▶"
            case "media-playback-pause": return "Ⅱ"
            case "media-seek-backward": return "◀◀"
            case "media-skip-backward": return "|◀"
            case "media-seek-forward": return "▶▶"
            case "media-skip-forward": return "▶|"
            case "media-playlist-shuffle": return "↝"
            default: return "•"
            }
        }
        color: icon.color
        font.pixelSize: Math.max(10, Math.min(width, height) * 0.62)
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideNone
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import org.kde.plasma.plasmoid

Item {
    id: root
    width: 300
    height: 400

    property var categories: [
        { name: "ETHNIC / FOLK / SPIRITUAL", url: "http://radcap.ru/ethnic-d.html" },
        { name: "REGGAE / SKA", url: "http://radcap.ru/reggae-d.html" },
        { name: "POP", url: "http://radcap.ru/pop-d.html" },
        { name: "ROCK", url: "http://radcap.ru/rock-d.html" },
        { name: "JAZZ", url: "http://radcap.ru/jazz-d.html" },
        { name: "METAL", url: "http://radcap.ru/metal-d.html" },
        { name: "HARDCORE", url: "http://radcap.ru/hardcore-d.html" },
        { name: "CLASSICAL", url: "http://radcap.ru/classic-d.html" },
        { name: "HIP-HOP / RAP", url: "http://radcap.ru/hh-d.html" },
        { name: "ELECTRONIC", url: "http://radcap.ru/electro-d.html" },
        { name: "MISCELLANEOUS", url: "http://radcap.ru/misc-d.html" },
        { name: "ШАНСОН", url: "http://radcap.ru/shanson-d.html" },
        { name: "BLUES / FUNK / SOUL / R&B", url: "http://radcap.ru/blues-d.html" },
        { name: "COUNTRY", url: "http://radcap.ru/country-d.html" },
        { name: "ВСЕ СТИЛИ,  ЖАНРЫ,  НАПРАВЛЕНИЯ,  КОМПИЛЯЦИИ", url: "http://radcap.ru/all-d.html" }
    ]

    property var stations: []
    property bool inCategory: false
    property string currentCategory: ""

    MediaPlayer {
        id: player
        autoPlay: false
        volume: volumeSlider.value
    }

    function loadCategory(cat) {
        currentCategory = cat.name
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                stations = parseStations(xhr.responseText)
                inCategory = true
            }
        }
        xhr.open("GET", cat.url)
        xhr.send()
    }

    function parseStations(html) {
        var regex = /href="(http:\/\/[^\"]+\.(?:m3u|pls|xspf))"[^>]*>([^<]+)/g
        var res = []
        var match
        while ((match = regex.exec(html)) !== null) {
            res.push({ name: match[2], url: match[1] })
        }
        return res
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        Loader {
            active: !inCategory
            sourceComponent: categoriesView
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Loader {
            active: inCategory
            sourceComponent: stationsView
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: player.playbackState === MediaPlayer.PlayingState ? "Stop" : "Play"
                onClicked: {
                    if (player.playbackState === MediaPlayer.PlayingState)
                        player.stop()
                    else
                        player.play()
                }
            }
            Slider {
                id: volumeSlider
                from: 0
                to: 1
                value: 0.5
                Layout.fillWidth: true
            }
        }
    }

    Component {
        id: categoriesView
        ListView {
            model: categories
            delegate: Item {
                width: parent.width
                height: 32
                Text {
                    text: model.name
                    anchors.verticalCenter: parent.verticalCenter
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: loadCategory(model)
                }
            }
        }
    }

    Component {
        id: stationsView
        ColumnLayout {
            RowLayout {
                Button {
                    text: "Back"
                    onClicked: inCategory = false
                }
                Label {
                    text: currentCategory
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            ListView {
                model: stations
                delegate: Item {
                    width: parent.width
                    height: 32
                    Text { text: model.name; anchors.verticalCenter: parent.verticalCenter }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            player.source = model.url
                            player.play()
                        }
                    }
                }
            }
        }
    }
}

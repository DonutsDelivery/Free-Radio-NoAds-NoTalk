import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 6.5
import org.kde.plasma.plasmoid
import org.kde.kirigami 2.20 as Kirigami
import "radiodata.js" as RadioData

PlasmoidItem {
    id: root
    width: Kirigami.Units.gridUnit * 20
    height: Kirigami.Units.gridUnit * 25

    // Load hard-coded categories and stations from JS file
    property var categories: RadioData.getCategories()

    property var stations: []
    property bool inCategory: false
    property string currentCategory: ""
    // streaming options
    property bool highQuality: true // port 8000 vs 8002
    property string playlistFormat: "m3u" // or "xspf"

    MediaPlayer {
        id: player
        autoPlay: false
        audioOutput: AudioOutput {
            id: audioOut
            volume: volumeSlider.value
        }
    }

    // Display the stations stored within the selected category
    function loadCategory(cat) {
        currentCategory = cat.name
        stations = cat.stations
        inCategory = true
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
            ComboBox {
                id: qualityBox
                model: ["High", "Low"]
                currentIndex: highQuality ? 0 : 1
                onCurrentIndexChanged: highQuality = currentIndex === 0
            }
            ComboBox {
                id: formatBox
                model: ["m3u", "xspf"]
                currentIndex: playlistFormat === "m3u" ? 0 : 1
                onCurrentIndexChanged: playlistFormat = currentIndex === 0 ? "m3u" : "xspf"
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
            delegate: ItemDelegate {
                // modelData represents the category object with 'name' and 'url'
                text: modelData.name
                onClicked: loadCategory(modelData)
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
                delegate: ItemDelegate {
                    // modelData contains the station object with host and path
                    text: modelData.name
                    onClicked: {
                        var port = highQuality ? "8000" : "8002"
                        var url = modelData.host + ":" + port + "/" + modelData.path + "." + playlistFormat
                        player.source = url
                        player.play()
                    }
                }
            }
        }
    }
}
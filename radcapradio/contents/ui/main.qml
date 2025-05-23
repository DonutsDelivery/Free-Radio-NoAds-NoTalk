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

    // List of categories and their stations loaded from radiodata.js
    property var categories: RadioData.categories

    property var stations: []
    property bool inCategory: false
    property string currentCategory: ""
    property string playlistFormat: "xspf"

    MediaPlayer {
        id: player
        autoPlay: false
        audioOutput: AudioOutput {
            id: audioOut
            volume: volumeSlider.value
        }
    }

    function loadCategory(cat) {
        currentCategory = cat.name
        stations = cat.stations || []
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
                id: formatBox
                model: ["xspf", "m3u"]
                currentIndex: 0
                onCurrentValueChanged: playlistFormat = currentValue
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
                    // modelData contains the station object
                    text: modelData.name
                    onClicked: {
                        player.source = modelData.url + "." + playlistFormat
                        player.play()
                    }
                }
            }
        }
    }
}
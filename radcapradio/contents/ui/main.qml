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

    // Models used by the views. Converting the plain arrays into
    // ListModels avoids issues with ListView when loading the data
    // directly from JavaScript.
    ListModel { id: categoriesModel }
    ListModel { id: stationsModel }

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

    Component.onCompleted: {
        // Populate the categories model once the UI loads
        for (var i = 0; i < categories.length; ++i) {
            categoriesModel.append(categories[i])
        }
    }

    function loadCategory(cat) {
        currentCategory = cat.name
        stationsModel.clear()
        var list = cat.stations || []
        for (var i = 0; i < list.length; ++i) {
            stationsModel.append(list[i])
        }
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
            model: categoriesModel
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
                    onClicked: {
                        inCategory = false
                        stationsModel.clear()
                    }
                }
                Label {
                    text: currentCategory
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            ListView {
                model: stationsModel
                delegate: ItemDelegate {
                    // modelData contains the station object
                    text: modelData.name
                    onClicked: {
                        player.source = modelData.host + "/" + modelData.path + "." + playlistFormat
                        player.play()
                    }
                }
            }
        }
    }
}

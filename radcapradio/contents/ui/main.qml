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

    property var categories: RadioData.categories
    property var categoriesModel: []

    property var stations: []
    property bool inCategory: false
    property string currentCategory: ""

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
        if (cat.name === "Favorites") {
            stations = favorites
        } else {
            stations = cat.stations
        }
        inCategory = true
    }

    property var favorites: []
    property bool highQuality: true
    property string playlistFormat: "xspf"

    Component.onCompleted: updateCategoriesModel()
    onFavoritesChanged: updateCategoriesModel()

    function isFavorite(station) {
        return favorites.some(function(s) { return s.name === station.name })
    }

    function toggleFavorite(station) {
        if (isFavorite(station)) {
            favorites = favorites.filter(function(s) { return s.name !== station.name })
        } else {
            favorites.push(station)
        }
        updateCategoriesModel()
    }

    function updateCategoriesModel() {
        categoriesModel = favorites.length ? [{ name: "Favorites", stations: favorites }].concat(categories) : categories
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
                model: ["Low", "High"]
                currentIndex: highQuality ? 1 : 0
                onCurrentIndexChanged: highQuality = (currentIndex === 1)
            }
            ComboBox {
                id: formatBox
                model: ["xspf", "m3u"]
                currentIndex: playlistFormat === "m3u" ? 1 : 0
                onCurrentIndexChanged: playlistFormat = currentText
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
                    RowLayout {
                        anchors.fill: parent
                        Label {
                            text: modelData.name
                            Layout.fillWidth: true
                        }
                        Button {
                            text: root.isFavorite(modelData) ? "\u2605" : "\u2606"
                            onClicked: root.toggleFavorite(modelData)
                        }
                    }
                    onClicked: {
                        var port = highQuality ? 8002 : 8000
                        var url = modelData.host + ":" + port + "/" + modelData.path + "." + playlistFormat
                        player.source = url
                        player.play()
                    }
                }
            }
        }
    }
}
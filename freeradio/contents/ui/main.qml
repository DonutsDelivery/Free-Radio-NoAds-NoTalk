// Free Radio - Standalone Kirigami Application
// This is the main entry point for the cross-platform standalone app
import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt.labs.settings 1.0
import org.kde.kirigami 2.20 as Kirigami

Kirigami.ApplicationWindow {
    id: window
    title: "Free Radio"
    width: 400
    height: 650
    minimumWidth: 300
    minimumHeight: 400
    visible: true

    // Persistent settings using QSettings
    Settings {
        id: persistentSettings
        property string favoriteStations: "[]"
        property string customStations: "[]"
        property string customEbooks: "[]"
        property string ebookProgress: "{}"
        property real volumeLevel: 0.8
        property string lastStationName: ""
        property string lastStationUrl: ""
        property string lastStationHost: ""
        property string lastStationPath: ""
    }

    // Main content - the shared UI component
    MainContent {
        id: mainContent
        anchors.fill: parent

        // Standalone mode - no panel integration
        isCompactMode: false
        isHorizontalPanel: false
        isVerticalPanel: false
        showPopup: false

        // Bind settings bidirectionally
        Component.onCompleted: {
            // Load settings into MainContent
            settings.favoriteStations = Qt.binding(function() { return persistentSettings.favoriteStations })
            settings.customStations = Qt.binding(function() { return persistentSettings.customStations })
            settings.customEbooks = Qt.binding(function() { return persistentSettings.customEbooks })
            settings.ebookProgress = Qt.binding(function() { return persistentSettings.ebookProgress })
            settings.volumeLevel = Qt.binding(function() { return persistentSettings.volumeLevel })
            settings.lastStationName = Qt.binding(function() { return persistentSettings.lastStationName })
            settings.lastStationUrl = Qt.binding(function() { return persistentSettings.lastStationUrl })
            settings.lastStationHost = Qt.binding(function() { return persistentSettings.lastStationHost })
            settings.lastStationPath = Qt.binding(function() { return persistentSettings.lastStationPath })
        }

        // Save changes back to persistent settings
        Connections {
            target: mainContent.settings
            function onFavoriteStationsChanged() { persistentSettings.favoriteStations = mainContent.settings.favoriteStations }
            function onCustomStationsChanged() { persistentSettings.customStations = mainContent.settings.customStations }
            function onCustomEbooksChanged() { persistentSettings.customEbooks = mainContent.settings.customEbooks }
            function onEbookProgressChanged() { persistentSettings.ebookProgress = mainContent.settings.ebookProgress }
            function onVolumeLevelChanged() { persistentSettings.volumeLevel = mainContent.settings.volumeLevel }
            function onLastStationNameChanged() { persistentSettings.lastStationName = mainContent.settings.lastStationName }
            function onLastStationUrlChanged() { persistentSettings.lastStationUrl = mainContent.settings.lastStationUrl }
            function onLastStationHostChanged() { persistentSettings.lastStationHost = mainContent.settings.lastStationHost }
            function onLastStationPathChanged() { persistentSettings.lastStationPath = mainContent.settings.lastStationPath }
        }
    }
}

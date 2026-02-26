// Free Radio - Standalone Application (no Plasma dependencies)
import QtQuick
import QtQuick.Controls
import Qt.labs.settings
import org.kde.kirigami as Kirigami
import SessionMonitor 1.0

Kirigami.ApplicationWindow {
    id: window
    title: "Free Radio"
    width: 400
    height: 650
    minimumWidth: 300
    minimumHeight: 400
    visible: true

    // Let dark theme control the window background
    background: Rectangle {
        color: mainContent.themeBg
        Behavior on color { ColorAnimation { duration: 200 } }
    }

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
        property string colorTheme: "amber"
        property string displayMode: "light"
    }

    // Screen lock detection — restart stream on unlock as safety net.
    // QT_AUDIO_BACKEND=pulseaudio uses pipewire-pulse ring buffer to survive
    // DPMS graph reconfiguration. Restart-on-unlock is a fallback if it still breaks.
    SessionMonitor {
        id: sessionMonitor
        onScreenUnlocked: mainContent.restartCurrentStream()
    }

    // Main content - the shared UI component
    MainContent {
        id: mainContent
        anchors.fill: parent
        sessionMonitor: sessionMonitor

        // Standalone mode - no panel integration
        isCompactMode: false
        isHorizontalPanel: false
        isVerticalPanel: false
        showPopup: false

        Component.onCompleted: {
            settings.favoriteStations = persistentSettings.favoriteStations
            settings.customStations = persistentSettings.customStations
            settings.customEbooks = persistentSettings.customEbooks
            settings.ebookProgress = persistentSettings.ebookProgress
            settings.volumeLevel = persistentSettings.volumeLevel
            settings.lastStationName = persistentSettings.lastStationName
            settings.lastStationUrl = persistentSettings.lastStationUrl
            settings.lastStationHost = persistentSettings.lastStationHost
            settings.lastStationPath = persistentSettings.lastStationPath
            settings.colorTheme = persistentSettings.colorTheme || "amber"
            settings.displayMode = persistentSettings.displayMode || "light"

            loadFavorites()
            loadCustomStations()
            loadCustomEbooks()
            loadEbookProgress()
            loadVolumeLevel()
            loadLastStation()
            loadSources()
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
            function onColorThemeChanged() { persistentSettings.colorTheme = mainContent.settings.colorTheme }
            function onDisplayModeChanged() { persistentSettings.displayMode = mainContent.settings.displayMode }
        }
    }
}

// Free Radio - KDE Plasma Widget Wrapper
// This wraps MainContent for use as a Plasma plasmoid
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Detect panel mode
    property bool isCompactMode: plasmoid.formFactor === PlasmaCore.Types.Horizontal ||
                                 plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool isHorizontalPanel: plasmoid.formFactor === PlasmaCore.Types.Horizontal
    property bool isVerticalPanel: plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Popup state for panel mode
    property bool showPopup: false

    // Panel button sizing
    property real panelButtonSize: {
        if (!isCompactMode) return 32
        if (isHorizontalPanel) return Math.max(16, Math.min(root.height * 0.8, 48))
        if (isVerticalPanel) return Math.max(16, Math.min(root.width * 0.8, 48))
        return 32
    }
    property real panelSpacing: isCompactMode ? Math.max(1, Math.min(4, panelButtonSize / 10)) : 4
    property real panelFontSize: isCompactMode ? Math.max(8, Math.min(16, panelButtonSize * 0.45)) : 12

    // Layout sizing
    Layout.minimumWidth: isCompactMode ? 100 : 280
    Layout.minimumHeight: isCompactMode ? 24 : 350
    Layout.preferredWidth: isCompactMode ? 140 : 380
    Layout.preferredHeight: isCompactMode ? 30 : 520

    // No background in widget mode
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Compact panel controls - shown when in panel mode
    Item {
        anchors.fill: parent
        visible: isCompactMode

        Row {
            anchors.centerIn: parent
            spacing: panelSpacing

            Button {
                text: "📻"
                width: panelButtonSize
                height: panelButtonSize
                flat: true
                onClicked: showPopup = !showPopup

                ToolTip.text: showPopup ? "Close Radio" : "Open Radio"
                ToolTip.visible: hovered
                ToolTip.delay: 1500

                contentItem: Text {
                    text: parent.text
                    font.pixelSize: panelFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.textColor
                }
            }

            Button {
                text: "⏮"
                width: panelButtonSize
                height: panelButtonSize
                onClicked: mainContent.sendRemoteCommand("previous")

                ToolTip.text: "Previous"
                ToolTip.visible: hovered

                background: Rectangle {
                    radius: parent.width / 2
                    color: parent.pressed ? Kirigami.Theme.highlightColor :
                           parent.hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.8) :
                           Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.6)
                }

                contentItem: Text {
                    text: parent.text
                    font.pixelSize: panelFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: parent.pressed || parent.hovered ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                }
            }

            Button {
                text: "⏯"
                width: panelButtonSize
                height: panelButtonSize
                onClicked: mainContent.sendRemoteCommand("playpause")

                ToolTip.text: "Play/Pause"
                ToolTip.visible: hovered

                background: Rectangle {
                    radius: parent.width / 2
                    color: parent.pressed ? Kirigami.Theme.highlightColor :
                           parent.hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.8) :
                           Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.6)
                }

                contentItem: Text {
                    text: parent.text
                    font.pixelSize: panelFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: parent.pressed || parent.hovered ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                }
            }

            Button {
                text: "⏭"
                width: panelButtonSize
                height: panelButtonSize
                onClicked: mainContent.sendRemoteCommand("next")

                ToolTip.text: "Next"
                ToolTip.visible: hovered

                background: Rectangle {
                    radius: parent.width / 2
                    color: parent.pressed ? Kirigami.Theme.highlightColor :
                           parent.hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.8) :
                           Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.6)
                }

                contentItem: Text {
                    text: parent.text
                    font.pixelSize: panelFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: parent.pressed || parent.hovered ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                }
            }
        }
    }

    // Main content - shown in desktop mode or popup
    MainContent {
        id: mainContent
        anchors.fill: parent
        visible: !isCompactMode || showPopup
        parent: showPopup ? popupContentContainer : root

        // Pass panel mode state
        isCompactMode: root.isCompactMode
        isHorizontalPanel: root.isHorizontalPanel
        isVerticalPanel: root.isVerticalPanel
        showPopup: root.showPopup

        // Initialize settings from plasmoid.configuration
        Component.onCompleted: {
            // Set initial values (not bindings, to avoid circular updates)
            settings.favoriteStations = plasmoid.configuration.favoriteStations || "[]"
            settings.customStations = plasmoid.configuration.customStations || "[]"
            settings.customEbooks = plasmoid.configuration.customEbooks || "[]"
            settings.ebookProgress = plasmoid.configuration.ebookProgress || "{}"
            settings.volumeLevel = plasmoid.configuration.volumeLevel !== undefined ? plasmoid.configuration.volumeLevel : 0.8
            settings.lastStationName = plasmoid.configuration.lastStationName || ""
            settings.lastStationUrl = plasmoid.configuration.lastStationUrl || ""
            settings.lastStationHost = plasmoid.configuration.lastStationHost || ""
            settings.lastStationPath = plasmoid.configuration.lastStationPath || ""
            settings.colorTheme = plasmoid.configuration.colorTheme || "amber"
            settings.displayMode = plasmoid.configuration.displayMode || "light"

            // Reload data with new settings
            console.log("Plasmoid wrapper: reloading data after settings bound")
            console.log("Favorites from config:", plasmoid.configuration.favoriteStations)
            loadFavorites()
            loadCustomStations()
            loadCustomEbooks()
            loadEbookProgress()
            loadVolumeLevel()
            loadLastStation()
            loadSources()
        }

        // Save changes back to plasmoid configuration
        Connections {
            target: mainContent.settings
            function onFavoriteStationsChanged() { plasmoid.configuration.favoriteStations = mainContent.settings.favoriteStations }
            function onCustomStationsChanged() { plasmoid.configuration.customStations = mainContent.settings.customStations }
            function onCustomEbooksChanged() { plasmoid.configuration.customEbooks = mainContent.settings.customEbooks }
            function onEbookProgressChanged() { plasmoid.configuration.ebookProgress = mainContent.settings.ebookProgress }
            function onVolumeLevelChanged() { plasmoid.configuration.volumeLevel = mainContent.settings.volumeLevel }
            function onLastStationNameChanged() { plasmoid.configuration.lastStationName = mainContent.settings.lastStationName }
            function onLastStationUrlChanged() { plasmoid.configuration.lastStationUrl = mainContent.settings.lastStationUrl }
            function onLastStationHostChanged() { plasmoid.configuration.lastStationHost = mainContent.settings.lastStationHost }
            function onLastStationPathChanged() { plasmoid.configuration.lastStationPath = mainContent.settings.lastStationPath }
            function onColorThemeChanged() { plasmoid.configuration.colorTheme = mainContent.settings.colorTheme }
            function onDisplayModeChanged() { plasmoid.configuration.displayMode = mainContent.settings.displayMode }
        }
    }

    // Popup window for compact/panel mode
    Window {
        id: radioPopup
        visible: showPopup && isCompactMode
        flags: Qt.Popup | Qt.FramelessWindowHint
        color: "transparent"

        width: Math.max(320, Math.min(400, Screen.desktopAvailableWidth * 0.25))
        height: Math.max(480, Math.min(650, Screen.desktopAvailableHeight * 0.5))

        x: {
            if (!root.parent) return 0
            var pos = root.mapToGlobal(0, 0)
            return Math.min(pos.x + root.width + 10, Screen.desktopAvailableWidth - width - 20)
        }

        y: {
            if (!root.parent) return 0
            var pos = root.mapToGlobal(0, 0)
            return Math.max(20, Math.min(pos.y - height/2 + root.height/2, Screen.desktopAvailableHeight - height - 20))
        }

        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            radius: 12
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)

            Rectangle {
                id: popupHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 40
                color: Qt.rgba(0, 0, 0, 0.1)
                radius: 12

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.radius
                    color: parent.color
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Free Radio"
                    font.bold: true
                    color: Kirigami.Theme.textColor
                }

                Button {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    flat: true
                    width: 24
                    height: 24
                    onClicked: showPopup = false

                    contentItem: Text {
                        text: parent.text
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Kirigami.Theme.textColor
                    }
                }
            }

            Item {
                id: popupContentContainer
                anchors.top: popupHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: showPopup = false
        }
    }
}

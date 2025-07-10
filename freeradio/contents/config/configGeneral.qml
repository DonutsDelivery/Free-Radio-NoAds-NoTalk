import QtQuick 2.0

Item {
    property alias cfg_favoriteStations: favoriteStations.text
    property alias cfg_autoMuteEnabled: autoMuteEnabled.checked
    
    // Hidden text field to store favorites JSON
    TextInput {
        id: favoriteStations
        visible: false
        text: "[]"
    }
    
    // Hidden checkbox for auto-mute setting
    CheckBox {
        id: autoMuteEnabled
        visible: false
        checked: false
    }
}
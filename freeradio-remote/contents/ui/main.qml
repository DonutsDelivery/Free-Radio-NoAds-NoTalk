import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root
    
    // Simple row of control buttons - no layouts that could conflict
    Row {
        anchors.centerIn: parent
        spacing: 4
        
        Button {
            text: "⏮"
            width: 32
            height: 32
            flat: true
            onClicked: sendRemoteCommand("previous")
            
            ToolTip.text: "Previous"
            ToolTip.visible: hovered
        }
        
        Button {
            text: "⏯"
            width: 32
            height: 32
            flat: true
            onClicked: sendRemoteCommand("playpause")
            
            ToolTip.text: "Play/Pause"
            ToolTip.visible: hovered
        }
        
        Button {
            text: "⏭"
            width: 32
            height: 32
            flat: true
            onClicked: sendRemoteCommand("next")
            
            ToolTip.text: "Next"
            ToolTip.visible: hovered
        }
    }
    
    function sendRemoteCommand(command) {
        console.log("Remote command:", command)
        
        // Send command via shared file
        var timestamp = new Date().getTime().toString()
        var commandData = command + ":" + timestamp
        
        // Write command to shared file
        var xhr = new XMLHttpRequest()
        xhr.open("POST", "file:///tmp/freeradio-remote-command", true)
        xhr.setRequestHeader("Content-Type", "text/plain")
        xhr.send(commandData)
        
        console.log("Sent remote command:", commandData)
    }
}
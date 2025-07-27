import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia 6.5
import org.kde.plasma.plasmoid
import org.kde.kirigami 2.20 as Kirigami

// Remote control component that shares the same plasmoid instance
Item {
    id: remoteRoot
    
    // Set compact size constraints for panel mode
    Layout.minimumWidth: 120
    Layout.minimumHeight: 32
    Layout.preferredWidth: 120
    Layout.preferredHeight: 32
    Layout.maximumWidth: 120
    Layout.maximumHeight: 32
    
    // Simple row of control buttons
    Row {
        anchors.centerIn: parent
        spacing: 2
        
        Button {
            text: "⏮"
            width: 36
            height: 28
            flat: true
            onClicked: {
                console.log("Remote: Previous button clicked")
                if (root.sendRemoteCommand) {
                    root.sendRemoteCommand("previous")
                }
            }
            
            ToolTip.text: "Previous"
            ToolTip.visible: hovered
        }
        
        Button {
            text: "⏯"
            width: 36
            height: 28
            flat: true
            onClicked: {
                console.log("Remote: Play/pause button clicked")
                if (root.sendRemoteCommand) {
                    root.sendRemoteCommand("playpause")
                }
            }
            
            ToolTip.text: "Play/Pause"
            ToolTip.visible: hovered
        }
        
        Button {
            text: "⏭"
            width: 36
            height: 28
            flat: true
            onClicked: {
                console.log("Remote: Next button clicked")
                if (root.sendRemoteCommand) {
                    root.sendRemoteCommand("next")
                }
            }
            
            ToolTip.text: "Next"
            ToolTip.visible: hovered
        }
    }
}
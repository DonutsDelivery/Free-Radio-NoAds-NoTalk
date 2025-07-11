import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia 6.5
import org.kde.plasma.plasmoid
import org.kde.kirigami 2.20 as Kirigami

// Remote control component that shares the same plasmoid instance
Item {
    id: remoteRoot
    
    // Simple row of control buttons
    Row {
        anchors.centerIn: parent
        spacing: 4
        
        Button {
            text: "⏮"
            width: 32
            height: 32
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
            width: 32
            height: 32
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
            width: 32
            height: 32
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
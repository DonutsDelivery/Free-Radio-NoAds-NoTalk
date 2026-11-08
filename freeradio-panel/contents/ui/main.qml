import QtQuick 2.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root
    
    // Simple compact-only widget
    Button {
        anchors.fill: parent
        text: "🎵"
        onClicked: {
            console.log("Panel widget clicked - would open full interface")
        }
        
        ToolTip.text: "DonutRadio Panel"
        ToolTip.visible: hovered
    }
}
import QtQuick 2.15
import QtMultimedia

// Absolutely minimal MediaPlayer - no event handlers that could cause loops
MediaPlayer {
    id: minimalPlayer
    
    Component.onCompleted: {
        console.log("MinimalPlayer: Basic MediaPlayer loaded")
    }
}
import QtQml
import FreeRadio.Audio 1.0

// The single playback authority shared by every MainContent surface.
// Both streams use the in-process decoder/output pipeline; no Qt Multimedia
// fallback is permitted because spectrum data must come from AudioEngine.
QtObject {
    id: controller

    property real volume: 0.8
    property bool muted: false
    property real previewVolumeScale: 0.7

    readonly property alias main: mainEngine
    readonly property alias preview: previewEngine
    readonly property alias spectrum: mainEngine.spectrum
    readonly property alias icyTitle: mainEngine.icyTitle
    readonly property alias icyName: mainEngine.icyName
    readonly property alias icyUrl: mainEngine.icyUrl

    readonly property int stoppedState: AudioEngine.StoppedState
    readonly property int loadingState: AudioEngine.LoadingState
    readonly property int bufferingState: AudioEngine.BufferingState
    readonly property int playingState: AudioEngine.PlayingState
    readonly property int pausedState: AudioEngine.PausedState
    readonly property int errorState: AudioEngine.ErrorState
    readonly property bool mainPlaying: mainEngine.playbackState === playingState
    readonly property bool mainActive: mainEngine.playbackState === loadingState
                                       || mainEngine.playbackState === bufferingState
                                       || mainEngine.playbackState === playingState
    readonly property bool previewPlaying: previewEngine.playbackState === playingState

    property AudioEngine _mainEngine: AudioEngine {
        id: mainEngine
        volume: controller.muted ? 0 : controller.volume
    }

    property AudioEngine _previewEngine: AudioEngine {
        id: previewEngine
        volume: controller.muted ? 0 : controller.volume * controller.previewVolumeScale
    }

    function playMain(source) {
        previewEngine.stop()
        if (source !== undefined && source !== null && source !== "")
            mainEngine.source = source
        mainEngine.play()
    }

    function pauseMain() {
        mainEngine.pause()
    }

    function suspendMain() {
        // Loading has no decoder session to pause yet, so cancellation is the
        // only way to guarantee a late network response cannot start audio.
        if (mainEngine.playbackState === loadingState)
            mainEngine.stop()
        else if (mainEngine.playbackState === bufferingState
                 || mainEngine.playbackState === playingState)
            mainEngine.pause()
    }

    function stopMain() {
        mainEngine.stop()
    }

    function restartMain(source) {
        mainEngine.stop()
        mainEngine.source = ""
        Qt.callLater(function() {
            if (source !== undefined && source !== null && source !== "")
                mainEngine.source = source
            mainEngine.play()
        })
    }

    function startPreview(source) {
        // Preview is exclusive: it always silences the main stream first.
        mainEngine.stop()
        previewEngine.stop()
        previewEngine.source = source
        previewEngine.play()
    }

    function stopPreview() {
        previewEngine.stop()
    }

    function stopAll() {
        previewEngine.stop()
        mainEngine.stop()
    }

    function seekMain(position) {
        if (!mainEngine.seekable || typeof mainEngine.seek !== "function") {
            console.warn("Seeking is unavailable for the current AudioEngine stream")
            return false
        }
        return mainEngine.seek(position) === true
    }
}

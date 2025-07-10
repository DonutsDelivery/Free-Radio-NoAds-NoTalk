#!/bin/bash
# PipeWire Audio Stream Monitor for Auto-Mute Feature
# This script monitors active audio streams and detects when other applications are playing audio

WIDGET_NAME="RadCap Radio"
EXCLUDE_PATTERNS=("plasma" "pipewire" "wireplumber" "pulseaudio" "systemd")

# Function to check if PipeWire is available
check_pipewire() {
    if ! command -v pw-cli &> /dev/null; then
        echo "ERROR: pw-cli not found. Please install pipewire-tools"
        exit 1
    fi
    
    if ! pgrep -x pipewire &> /dev/null; then
        echo "ERROR: PipeWire daemon not running"
        exit 1
    fi
}

# Function to get active audio streams
get_active_streams() {
    # Get all active sink inputs (playing audio applications)
    pw-cli ls Node 2>/dev/null | grep -A 20 "media.class.*Stream/Output/Audio" | \
    grep -E "(application.name|node.name|media.name)" | \
    grep -v monitor | \
    sed 's/.*= "//' | sed 's/"$//' | \
    grep -v "^$"
}

# Function to check for other audio applications
check_other_audio() {
    local streams
    streams=$(get_active_streams)
    
    if [ -z "$streams" ]; then
        echo "NO_AUDIO"
        return 1
    fi
    
    # Filter out our own application and system sounds
    local other_audio=false
    while IFS= read -r stream; do
        # Skip empty lines
        [ -z "$stream" ] && continue
        
        # Skip our own application
        if echo "$stream" | grep -qi "radcap\|radio"; then
            continue
        fi
        
        # Skip system applications
        local is_system=false
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            if echo "$stream" | grep -qi "$pattern"; then
                is_system=true
                break
            fi
        done
        
        if [ "$is_system" = false ]; then
            echo "OTHER_AUDIO_DETECTED: $stream" >&2
            other_audio=true
        fi
    done <<< "$streams"
    
    if [ "$other_audio" = true ]; then
        echo "OTHER_AUDIO"
        return 0
    else
        echo "NO_OTHER_AUDIO"
        return 1
    fi
}

# Function to monitor MPRIS media players
check_mpris_players() {
    local active_players
    active_players=$(busctl --user list 2>/dev/null | grep "org.mpris.MediaPlayer2" | wc -l)
    
    if [ "$active_players" -gt 0 ]; then
        # Check if any player is actually playing
        local playing_count=0
        while IFS= read -r service; do
            if [ -n "$service" ]; then
                local status
                status=$(busctl --user get-property "$service" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player PlaybackStatus 2>/dev/null | cut -d'"' -f2)
                if [ "$status" = "Playing" ]; then
                    playing_count=$((playing_count + 1))
                fi
            fi
        done <<< "$(busctl --user list 2>/dev/null | grep "org.mpris.MediaPlayer2" | awk '{print $1}')"
        
        if [ "$playing_count" -gt 0 ]; then
            echo "MPRIS_PLAYING: $playing_count players" >&2
            return 0
        fi
    fi
    
    return 1
}

# Main monitoring function
main() {
    check_pipewire
    
    case "${1:-monitor}" in
        "check")
            # Single check mode
            if check_other_audio || check_mpris_players; then
                echo "OTHER_AUDIO_DETECTED"
                exit 0
            else
                echo "NO_OTHER_AUDIO"
                exit 1
            fi
            ;;
        "monitor")
            # Continuous monitoring mode
            echo "Starting PipeWire audio monitoring..." >&2
            while true; do
                if check_other_audio || check_mpris_players; then
                    echo "OTHER_AUDIO_DETECTED"
                else
                    echo "NO_OTHER_AUDIO"
                fi
                sleep 2
            done
            ;;
        "debug")
            # Debug mode - show all streams
            echo "=== Active Audio Streams ===" >&2
            get_active_streams >&2
            echo "=== MPRIS Players ===" >&2
            busctl --user list 2>/dev/null | grep "org.mpris.MediaPlayer2" >&2
            check_other_audio
            ;;
        *)
            echo "Usage: $0 [check|monitor|debug]"
            echo "  check   - Single check and exit"
            echo "  monitor - Continuous monitoring (default)"
            echo "  debug   - Show debug information"
            exit 1
            ;;
    esac
}

main "$@"
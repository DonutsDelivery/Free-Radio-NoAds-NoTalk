#!/bin/bash
# Script to check for active audio sources (PipeWire/PulseAudio compatible)

# Exit codes:
# 0 = Other audio detected
# 1 = No other audio detected  
# 2 = Error/unable to determine

# Check if PipeWire is running
if command -v pw-cli &> /dev/null && pgrep -x pipewire &> /dev/null; then
    # Use PipeWire commands
    echo "Checking PipeWire audio sources..." >&2
    
    # Count active audio streams (excluding monitors)
    ACTIVE_STREAMS=$(pw-cli ls Node 2>/dev/null | grep -E "media\.class.*Audio" | grep -v monitor | wc -l)
    
    # Check for MPRIS media players
    MPRIS_PLAYERS=$(busctl --user list | grep -c "org.mpris.MediaPlayer2" 2>/dev/null || echo 0)
    
    echo "Active audio streams: $ACTIVE_STREAMS" >&2
    echo "MPRIS players: $MPRIS_PLAYERS" >&2
    
    # If more than 1 audio stream (assuming our radio is 1), other audio is likely playing
    if [ "$ACTIVE_STREAMS" -gt 1 ] || [ "$MPRIS_PLAYERS" -gt 0 ]; then
        echo "OTHER_AUDIO_DETECTED"
        exit 0
    else
        echo "NO_OTHER_AUDIO"
        exit 1
    fi
    
elif command -v pactl &> /dev/null; then
    # Fallback to PulseAudio commands
    echo "Checking PulseAudio sources..." >&2
    
    # Count sink inputs (active audio playback)
    SINK_INPUTS=$(pactl list sink-inputs 2>/dev/null | grep -c "Sink Input" || echo 0)
    
    # Check MPRIS players
    MPRIS_PLAYERS=$(busctl --user list | grep -c "org.mpris.MediaPlayer2" 2>/dev/null || echo 0)
    
    echo "Sink inputs: $SINK_INPUTS" >&2
    echo "MPRIS players: $MPRIS_PLAYERS" >&2
    
    # If more than 1 sink input or any MPRIS players, other audio likely playing
    if [ "$SINK_INPUTS" -gt 1 ] || [ "$MPRIS_PLAYERS" -gt 0 ]; then
        echo "OTHER_AUDIO_DETECTED"
        exit 0
    else
        echo "NO_OTHER_AUDIO"
        exit 1
    fi
    
else
    echo "No audio system detected (neither PipeWire nor PulseAudio)" >&2
    echo "ERROR"
    exit 2
fi
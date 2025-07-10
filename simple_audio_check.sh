#!/bin/bash
# Simple audio detection for RadCap auto-mute
# Returns 0 if other audio is playing, 1 if not

# Check for active PipeWire streams
if command -v pw-cli &> /dev/null; then
    # Count active output streams (excluding monitors)
    STREAMS=$(pw-cli ls Node 2>/dev/null | grep -c "Stream/Output/Audio")
    
    # If more than 1 stream (our radio + another app), other audio is playing
    if [ "$STREAMS" -gt 1 ]; then
        echo "OTHER_AUDIO"
        exit 0
    fi
fi

# Check for MPRIS players
if command -v busctl &> /dev/null; then
    MPRIS_PLAYING=$(busctl --user list 2>/dev/null | grep "org.mpris.MediaPlayer2" | wc -l)
    if [ "$MPRIS_PLAYING" -gt 0 ]; then
        echo "MPRIS_AUDIO"
        exit 0
    fi
fi

# No other audio detected
echo "NO_OTHER_AUDIO"
exit 1
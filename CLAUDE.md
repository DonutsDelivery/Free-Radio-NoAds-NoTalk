## Architecture Decisions

- Never fallback to QT mediaplayer for audio output. We want to use our own custom mediaplayer that is contained within the same process as everything else.
- We must never fall back to using QT mediaplayer because we cannot process the audio for our spectrum visualizer when it isnt coming from its own process.

## Maintenance Notes

- Use guide in WIDGET_REINSTALL_CONTEXT.md when reinstalling the widget
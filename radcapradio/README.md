# RadCap Radio Plasma Widget

This KDE Plasma 5 widget lists radio genres from **radcap.ru**. Selecting a genre loads the
radio channels for that category. Clicking a channel starts streaming with
play/stop and volume controls always available at the bottom of the widget.

The widget retrieves the HTML pages from `radcap.ru` and extracts links ending in
`m3u`, `pls` or `xspf`. These links are used as the stream source for playback.

## Installation

1. From the repository root, run:

   ```bash
   kpackagetool5 --install radcapradio
   ```

   This installs the widget directly from the `radcapradio` folder.
2. Optionally create a `.plasmoid` archive for manual distribution:

   ```bash
   zip -r RadCapRadio.plasmoid radcapradio
   ```

3. Add **RadCap Radio** from the Plasma widget list.


# RadCap Radio Plasma Widget

This KDE Plasma **6** widget lists radio genres from **radcap.ru**. Selecting a genre loads the
radio channels for that category. Clicking a channel starts streaming with
play/stop and volume controls always available at the bottom of the widget.

The widget retrieves the HTML pages from `radcap.ru` and extracts links ending in
`m3u`, `pls` or `xspf`. These links are used as the stream source for playback.

## Installation

1. Run `kpackagetool6 --install radcapradio` from this repository root.
2. Alternatively, create `RadCapRadio.plasmoid` with:
   `zip -r RadCapRadio.plasmoid radcapradio` and install the archive.
3. Add "RadCap Radio" from the Plasma widget list.


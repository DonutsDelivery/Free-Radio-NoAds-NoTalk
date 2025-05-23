# RadCap Radio Plasma Widget

This KDE Plasma **6** widget lists radio genres from a bundled dataset. The user
interface uses **Kirigami** components for a modern look. Selecting a genre
shows the channels contained in `radiodata.js`; clicking a channel starts
streaming with play/stop and volume controls always available at the bottom of
the widget.

No network access is required at runtime since the station list is hard coded.
The selected playlist format (`xspf` or `m3u`) is appended to each station URL
when playback begins.

## Installation

1. Run `kpackagetool6 --install radcapradio` from this repository root.
   The command may show a `QDBusConnection` warning about `/KPackage/`. This
   message is harmless and the widget installs correctly.
2. Alternatively, create `RadCapRadio.plasmoid` with:
   `zip -r RadCapRadio.plasmoid radcapradio` and install the archive.
3. Add "RadCap Radio" from the Plasma widget list.
   If you see a `QDBusConnection` warning during installation, it can be safely ignored.


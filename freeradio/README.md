# DonutRadio Plasma Widget

This KDE Plasma **6** widget lists radio genres from a bundled dataset. The user
interface uses **Kirigami** components for a modern look. Selecting a genre
shows the channels contained in `radiodata.js`; clicking a channel starts
streaming with play/stop and volume controls always available at the bottom of
the widget.

No network access is required at runtime since the station list is hard coded.
The selected playlist format (`xspf` or `m3u`) is appended to each station URL
when playback begins.

The widget id is `online.donutsdelivery.donutradio`. The package manager and
`kpackagetool6` both use that id as the install directory name.

## Installation

1. Run `kpackagetool6 --type Plasma/Applet --install freeradio` from the
   repository root. The command may show a `QDBusConnection` warning about
   `/KPackage/`. This message is harmless and the widget installs correctly.
2. Alternatively, build the archive with
   `cd freeradio && zip -r ../donutradio.plasmoid metadata.json contents -x "*.backup"`
   and install it with `kpackagetool6 --type Plasma/Applet --install donutradio.plasmoid`.
3. Add "DonutRadio" from the Plasma widget list.

Installing the DonutRadio app (`cmake --install`, or the `donutradio` AUR
package) also installs the widget, so none of these steps are needed then.
If an older install exists under the `freeradio` or `radcapradio` id, remove it
first, for example `kpackagetool6 --type Plasma/Applet --remove freeradio`.

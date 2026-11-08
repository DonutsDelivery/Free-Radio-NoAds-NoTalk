# DonutRadio Plasma Widget

This KDE Plasma **6** widget lists radio genres from a bundled dataset. The user
interface uses **Kirigami** components for a modern look. Selecting a genre
shows the channels contained in `radiodata.js`; clicking a channel starts
streaming with play/stop and volume controls always available at the bottom of
the widget.

The station metadata is bundled and can be browsed without network access;
playing a station requires network access. The selected playlist format (`xspf`
or `m3u`) is appended to each station URL when playback begins.

## Station catalog maintenance

Edit only `freeradio/catalog/radiodata.json`, preserving array order because it
is user-visible and a favorite identity is the exact `name` + `host` + `path`
triple. Then run:

```sh
python3 tools/radiodata_catalog.py generate
python3 tools/radiodata_catalog.py check
python3 -m unittest discover -s tests
```

`check` includes validation. `freeradio/contents/ui/radiodata.js` and the JSON
Schema are deterministic generated compatibility files and must not be
hand-edited. Repeated stream identities must stay listed with their exact
reviewed occurrences and a reason in `allowedDuplicateStreams`; validation
reports all known repetitions and rejects undeclared, changed, or stale entries.
The migration baseline deliberately detects station renames, reorderings, and
removals. After reviewing an intentional compatibility change, accept it
explicitly with `python3 tools/radiodata_catalog.py update-baseline`.

`freeradio/contents/ui/radiodata_radcap.js` is a retired, noncanonical legacy
snapshot: it remains in the source tree for provenance but is excluded from both
the standalone resources and Plasma artifact. Likewise,
`freeradio-panel/contents/ui/radiodata.js` is a noncanonical legacy copy. Neither
is synchronized by this generator. The root `generate_radiodata.py` and
`generate_all_categories.py` scripts are deprecated research helpers and refuse
to write catalog output. Installed user-data copies are likewise noncanonical
deployment artifacts; do not merge them back without review.

The widget id is `online.donutsdelivery.donutradio`. The package manager and
`kpackagetool6` both use that id as the install directory name.

## Installation

1. Run `kpackagetool6 --type Plasma/Applet --install freeradio` from the
   repository root. The command may show a `QDBusConnection` warning about
   `/KPackage/`. This message is harmless and the widget installs correctly.
2. Alternatively, build the archive with
   `cd freeradio && zip -r ../donutradio.plasmoid metadata.json contents -x "*.backup" -x contents/ui/radiodata_radcap.js`
   and install it with `kpackagetool6 --type Plasma/Applet --install donutradio.plasmoid`.
3. Add "DonutRadio" from the Plasma widget list.

Installing the DonutRadio app (`cmake --install`, or the `donutradio` AUR
package) also installs the widget, so none of these steps are needed then.
If an older install exists under the `freeradio` or `radcapradio` id, remove it
first, for example `kpackagetool6 --type Plasma/Applet --remove freeradio`.

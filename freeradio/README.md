# RadCap Radio Plasma Widget

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
is user-visible and station `host`/`path` pairs are favorite identities. Then run:

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

Other catalog-looking files, including
`freeradio/contents/ui/radiodata_radcap.js` and
`freeradio-panel/contents/ui/radiodata.js`, are noncanonical legacy copies and
are not synchronized or bundled by this generator. The root
`generate_radiodata.py` and `generate_all_categories.py` scripts are deprecated
research helpers and refuse to write catalog output. Installed user-data copies
are likewise noncanonical deployment artifacts; do not merge them back without
review.

## Installation

1. Run `kpackagetool6 --install radcapradio` from this repository root.
   The command may show a `QDBusConnection` warning about `/KPackage/`. This
   message is harmless and the widget installs correctly.
2. Alternatively, create `RadCapRadio.plasmoid` with:
   `zip -r RadCapRadio.plasmoid radcapradio` and install the archive.
3. Add "RadCap Radio" from the Plasma widget list.
   If you see a `QDBusConnection` warning during installation, it can be safely ignored.


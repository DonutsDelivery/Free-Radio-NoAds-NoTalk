# Free-Radio-NoAds-NoTalk

This repository contains the **RadCap Radio** KDE Plasma widget. The widget
provides quick access to radio genres available on [radcap.ru](http://radcap.ru).

## Installation

This repository does not ship a pre‑built `.plasmoid` package. Install the
widget directly from the source directory:

```bash
kpackagetool5 --install radcapradio
```

Alternatively, package the folder into a `.plasmoid` archive for manual
installation:

```bash
zip -r RadCapRadio.plasmoid radcapradio
```

After installation, add **RadCap Radio** from the Plasma widget list.
# AUR submission guide for donutradio

This guide covers publishing the `donutradio` package to the Arch User Repository (AUR). The package builds the DonutRadio app and installs the DonutRadio Plasma 6 widget with it. It replaces the older `plasma6-applet-freeradio` package.

## Prerequisites

1. An AUR account (https://aur.archlinux.org/register/).
2. An SSH key added to that account.
3. `git` and `makepkg` installed.

## Files

- `PKGBUILD` builds `freeradio/` with CMake and runs `cmake --install` into the package.
- `.SRCINFO` is the AUR metadata. Regenerate it with `makepkg --printsrcinfo > .SRCINFO`.

## Package details

- Name: `donutradio` (provides, conflicts with and replaces `plasma6-applet-freeradio`)
- Version: the CMake project version in `freeradio/CMakeLists.txt`, kept equal to `pkgver`
- License: GPL-2.0-or-later
- Installs: `/usr/bin/donutradio`, the desktop file, the AppStream metainfo, hicolor icons, and the widget at `/usr/share/plasma/plasmoids/online.donutsdelivery.donutradio`
- Optional dependency: `plasma-workspace` for the widget

## Steps

### 1. Tag the release and set the checksum

The source is the GitHub tag archive for `v$pkgver`. Push the tag first, then:

```bash
curl -L "https://github.com/DonutsDelivery/Free-Radio-NoAds-NoTalk/archive/v2.0.0.tar.gz" | sha256sum
```

Put the result in `sha256sums` (it is `SKIP` until then) and regenerate `.SRCINFO`.

### 2. Test the build

```bash
makepkg -si
```

### 3. Create the AUR repository

```bash
git clone ssh://aur@aur.archlinux.org/donutradio.git aur-package
cd aur-package
cp ../PKGBUILD ../.SRCINFO .
git add PKGBUILD .SRCINFO
git commit -m "Initial upload: donutradio 2.0.0"
git push origin master
```

Check https://aur.archlinux.org/packages/donutradio afterwards.

## Updating

1. Bump `pkgver` in the PKGBUILD and reset `pkgrel` to 1.
2. Update `sha256sums`.
3. Regenerate `.SRCINFO`.
4. Commit and push to the AUR repository.

## Renaming from plasma6-applet-freeradio

Upload `donutradio` as a new package. Then ask the AUR maintainers to merge or delete the old `plasma6-applet-freeradio` package so users get the replacement through `replaces`.

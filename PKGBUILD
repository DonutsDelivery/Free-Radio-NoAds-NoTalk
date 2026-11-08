# Maintainer: DonutsDelivery <megusta52@proton.me>
pkgname=donutradio
pkgver=2.0.0
pkgrel=1
pkgdesc="Internet radio player with curated ad-free stations, plus a KDE Plasma 6 widget"
arch=('x86_64' 'aarch64')
url="https://github.com/DonutsDelivery/Free-Radio-NoAds-NoTalk"
license=('GPL-2.0-or-later')
depends=('qt6-base' 'qt6-declarative' 'qt6-multimedia' 'kirigami' 'qqc2-desktop-style'
         'libpulse' 'hicolor-icon-theme')
makedepends=('cmake' 'extra-cmake-modules')
optdepends=('plasma-workspace: DonutRadio widget for Plasma 6 panels and desktops')
provides=('plasma6-applet-freeradio')
conflicts=('plasma6-applet-freeradio')
replaces=('plasma6-applet-freeradio')
source=("$pkgname-$pkgver.tar.gz::$url/archive/v$pkgver.tar.gz")
# Replace SKIP with the real checksum once the release tag exists.
sha256sums=('SKIP')

_srcdir() {
    echo "$srcdir/Free-Radio-NoAds-NoTalk-$pkgver"
}

prepare() {
    cd "$(_srcdir)"

    if [[ ! -f freeradio/CMakeLists.txt ]]; then
        error "freeradio/CMakeLists.txt not found in the source tree"
        return 1
    fi
}

build() {
    cmake -B build -S "$(_srcdir)/freeradio" \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build build
}

package() {
    # Installs the donutradio binary, the desktop file, the AppStream metainfo,
    # the hicolor icons and the Plasma widget (share/plasma/plasmoids/online.donutsdelivery.donutradio).
    DESTDIR="$pkgdir" cmake --install build

    local plasmoid="$pkgdir/usr/share/plasma/plasmoids/online.donutsdelivery.donutradio"
    if [[ ! -f "$plasmoid/metadata.json" || ! -f "$plasmoid/contents/ui/main.qml" ]]; then
        error "Plasma widget was not installed"
        return 1
    fi
    if [[ ! -x "$pkgdir/usr/bin/donutradio" ]]; then
        error "donutradio binary was not installed"
        return 1
    fi
}

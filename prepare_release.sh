#!/bin/bash
# Prepare Release for AUR Submission

set -e

VERSION="1.5.6"
PKGNAME="plasma6-applet-freeradio"

echo "=== Preparing Release v$VERSION for AUR ==="

# Verify we're in the right directory
if [[ ! -f "freeradio/metadata.json" ]]; then
    echo "Error: Run this script from the project root directory"
    exit 1
fi

# Check if version matches metadata.json
METADATA_VERSION=$(grep '"Version"' freeradio/metadata.json | cut -d'"' -f4)
if [[ "$METADATA_VERSION" != "$VERSION" ]]; then
    echo "Warning: Version mismatch!"
    echo "  Script version: $VERSION"
    echo "  metadata.json version: $METADATA_VERSION"
    echo "  Please update metadata.json or this script"
    exit 1
fi

# Test build locally
echo "=== Testing local build ==="
if command -v makepkg &> /dev/null; then
    echo "Testing PKGBUILD..."
    makepkg -f --noextract --nodeps --nobuild
    echo "✓ PKGBUILD syntax is valid"
else
    echo "makepkg not found, skipping build test"
fi

# Verify required files exist
echo "=== Verifying required files ==="
required_files=(
    "PKGBUILD"
    ".SRCINFO"
    "freeradio/metadata.json"
    "freeradio/contents/ui/main.qml"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✓ $file"
    else
        echo "✗ Missing: $file"
        exit 1
    fi
done

# Check git status
echo "=== Git Status ==="
if git status --porcelain | grep -q .; then
    echo "Warning: Uncommitted changes detected"
    git status --short
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create/verify git tag
echo "=== Git Tag ==="
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
    echo "✓ Tag v$VERSION already exists"
else
    echo "Creating tag v$VERSION..."
    git tag -a "v$VERSION" -m "Release version $VERSION

- Revert to Qt MediaPlayer for reliable audio playback
- Remove experimental spectrum visualizer
- Stable radio streaming functionality
- Compatible with KDE Plasma 6"
    echo "✓ Created tag v$VERSION"
    echo "Remember to push the tag: git push origin v$VERSION"
fi

# Generate SHA256 checksum for release
echo "=== Generating SHA256 for AUR ==="
ARCHIVE_URL="https://github.com/DonutsDelivery/Free-Radio-NoAds-NoTalk/archive/v$VERSION.tar.gz"
echo "Archive URL: $ARCHIVE_URL"
echo ""
echo "To get the actual SHA256 checksum:"
echo "1. Push the tag to GitHub: git push origin v$VERSION"
echo "2. Download: curl -L '$ARCHIVE_URL' | sha256sum"
echo "3. Update PKGBUILD with the real checksum (replace 'SKIP')"

echo ""
echo "=== Next Steps ==="
echo "1. Push git tag: git push origin v$VERSION"
echo "2. Update SHA256 in PKGBUILD"
echo "3. Regenerate .SRCINFO: makepkg --printsrcinfo > .SRCINFO"
echo "4. Follow AUR_SUBMISSION_GUIDE.md"
echo ""
echo "Release preparation complete! ✓"
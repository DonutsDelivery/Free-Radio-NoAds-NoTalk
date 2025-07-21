# AUR Submission Guide for plasma6-applet-freeradio

This guide explains how to submit the Free Radio widget to the Arch User Repository (AUR).

## Prerequisites

1. **AUR Account**: Create an account at https://aur.archlinux.org/register/
2. **SSH Key**: Generate and add SSH key to your AUR account
3. **Git**: Ensure git is installed and configured

## Files Created

- `PKGBUILD` - Build script for Arch Linux
- `.SRCINFO` - Package metadata for AUR
- `AUR_SUBMISSION_GUIDE.md` - This guide

## Package Details

- **Package Name**: `plasma6-applet-freeradio`
- **Version**: 1.5.6
- **Description**: Ad-free internet radio widget for KDE Plasma 6
- **License**: GPL-2.0-or-later
- **Dependencies**:
  - plasma-workspace
  - qt6-multimedia
  - qt6-declarative
- **Optional Dependencies**:
  - qt6-websockets (Enhanced streaming features)

## Steps to Submit to AUR

### 1. Generate SSH Key (if not done already)
```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub
```
Copy the public key and add it to your AUR account settings.

### 2. Test Build Locally
```bash
# In the project directory
makepkg -si
```
This will test if the package builds correctly.

### 3. Create AUR Repository
```bash
git clone ssh://aur@aur.archlinux.org/plasma6-applet-freeradio.git aur-package
cd aur-package
```

### 4. Copy Package Files
```bash
cp ../PKGBUILD .
cp ../.SRCINFO .
```

### 5. Commit and Push
```bash
git add PKGBUILD .SRCINFO
git commit -m "Initial upload: plasma6-applet-freeradio 1.5.6

Ad-free internet radio widget for KDE Plasma 6.
Features:
- Multiple radio sources (radcap.ru, icecast)
- No ads or talk shows
- Kirigami UI components
- Qt6 MediaPlayer support
"

git push origin master
```

### 6. Verify Upload
Visit https://aur.archlinux.org/packages/plasma6-applet-freeradio to confirm the package was uploaded successfully.

## Package Testing

Users can install the package using an AUR helper:

```bash
# Using yay
yay -S plasma6-applet-freeradio

# Using paru
paru -S plasma6-applet-freeradio

# Manual installation
git clone https://aur.archlinux.org/plasma6-applet-freeradio.git
cd plasma6-applet-freeradio
makepkg -si
```

## Updating the Package

When releasing new versions:

1. Update `pkgver` in PKGBUILD
2. Reset `pkgrel` to 1
3. Update SHA256 checksum if needed
4. Regenerate .SRCINFO: `makepkg --printsrcinfo > .SRCINFO`
5. Commit and push changes

## Notes

- The package is architecture-independent (`arch=('any')`)
- Uses manual installation fallback if CMake build fails
- Includes proper file permissions and verification
- Conflicts with older plasma5 versions to prevent conflicts

## Support

For AUR-specific issues, users should:
1. Check the AUR comments section
2. Report issues on the GitHub repository
3. Follow Arch Linux packaging guidelines

## Maintenance

As the package maintainer, monitor:
- User comments on AUR page
- Build failures reported by users
- New releases from upstream
- Dependency changes in Plasma 6
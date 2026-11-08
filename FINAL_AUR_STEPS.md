> Historical checklist from the original `plasma6-applet-freeradio` submission. The package is now `donutradio`; see `AUR_SUBMISSION_GUIDE.md`.

# Final AUR Submission Steps for DonutsDelivery

## ✅ Completed:
- SSH key created: `~/.ssh/aur_key.pub`
- SSH config configured for AUR
- PKGBUILD created with maintainer: DonutsDelivery
- .SRCINFO generated
- Release v1.5.6 tagged and pushed to GitHub
- All files committed to repository

## 🔑 Your SSH Public Key (copy to AUR):
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFBDKsDg6RiRwSXfT9bJ6CQoQAj02fyl/pWuMpHnZDrq megusta52@proton.me
```

## 📋 Remaining Steps:

### 1. **Add SSH Key to AUR Account**
- Login to https://aur.archlinux.org/ with your DonutsDelivery account
- Go to "My Account" → "SSH Public Keys"  
- Paste the SSH key above and save

### 2. **Get Real SHA256 Checksum**
```bash
# Download the release and get checksum
curl -L "https://github.com/DonutsDelivery/Free-Radio-NoAds-NoTalk/archive/v1.5.6.tar.gz" | sha256sum
```

### 3. **Update PKGBUILD with Real Checksum**
- Replace `sha256sums=('SKIP')` with the actual checksum
- Regenerate .SRCINFO: `makepkg --printsrcinfo > .SRCINFO`

### 4. **Clone AUR Repository**
```bash
git clone ssh://aur@aur.archlinux.org/plasma6-applet-freeradio.git aur-freeradio
cd aur-freeradio
```

### 5. **Submit to AUR**
```bash
# Copy package files
cp ../PKGBUILD ../SRCINFO .

# Commit and push
git add PKGBUILD .SRCINFO
git commit -m "Initial upload: plasma6-applet-freeradio 1.5.6

Ad-free internet radio widget for KDE Plasma 6
- Qt6 MediaPlayer implementation
- Multiple radio sources (radcap.ru, icecast)
- Kirigami UI components
- No ads or talk shows"

git push origin master
```

### 6. **Verify Submission**
Check https://aur.archlinux.org/packages/plasma6-applet-freeradio

## 🎉 After Submission:
Users can install with:
```bash
yay -S plasma6-applet-freeradio
# or
paru -S plasma6-applet-freeradio
```

## 📞 Support:
- Monitor AUR comments
- GitHub issues: https://github.com/DonutsDelivery/Free-Radio-NoAds-NoTalk/issues
- Update package when you release new versions

Your package is ready for AUR! 🚀
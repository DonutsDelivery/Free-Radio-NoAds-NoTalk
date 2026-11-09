$ErrorActionPreference = 'Stop'

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url64bit       = 'https://github.com/DonutsDelivery/Free-Radio-NoAds-NoTalk/releases/download/v2.3.0/DonutRadio-Setup-x64.exe'
  checksum64     = 'f480fae1af7d64590d793f318a24e89ec344ee45157e3789c94f0db934d218e3'
  checksumType64 = 'sha256'
  silentArgs     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
  validExitCodes = @(0)
  softwareName   = 'DonutRadio*'
}

Install-ChocolateyPackage @packageArgs

; DonutRadio NSIS Installer Script
; Requires: NSIS 3.x

!include "MUI2.nsh"

; General
Name "DonutRadio"
OutFile "DonutRadio-2.0.0-Setup.exe"
InstallDir "$PROGRAMFILES64\DonutRadio"
InstallDirRegKey HKLM "Software\DonutRadio" "Install_Dir"
RequestExecutionLevel admin

; Interface Settings
!define MUI_ABORTWARNING
!define MUI_ICON "..\..\freeradio\icons\donutradio.ico"
!define MUI_UNICON "..\..\freeradio\icons\donutradio.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

; Installer Sections
Section "DonutRadio" SecMain
    SetOutPath $INSTDIR

    ; Copy application files
    File /r "..\..\build-windows\release\*.*"

    ; Copy Qt plugins and QML modules
    SetOutPath $INSTDIR\platforms
    File /r "..\..\build-windows\release\platforms\*.*"

    SetOutPath $INSTDIR\styles
    File /r "..\..\build-windows\release\styles\*.*"

    ; Create shortcuts
    CreateDirectory "$SMPROGRAMS\DonutRadio"
    CreateShortcut "$SMPROGRAMS\DonutRadio\DonutRadio.lnk" "$INSTDIR\donutradio.exe"
    CreateShortcut "$SMPROGRAMS\DonutRadio\Uninstall.lnk" "$INSTDIR\uninstall.exe"
    CreateShortcut "$DESKTOP\DonutRadio.lnk" "$INSTDIR\donutradio.exe"

    ; Write registry keys
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DonutRadio" "DisplayName" "DonutRadio"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DonutRadio" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DonutRadio" "DisplayIcon" "$INSTDIR\donutradio.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DonutRadio" "Publisher" "DonutsDelivery"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DonutRadio" "DisplayVersion" "2.0.0"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DonutRadio" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DonutRadio" "NoRepair" 1

    ; Create uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

; Uninstaller Section
Section "Uninstall"
    ; Remove files
    RMDir /r "$INSTDIR"

    ; Remove shortcuts
    Delete "$SMPROGRAMS\DonutRadio\*.*"
    RMDir "$SMPROGRAMS\DonutRadio"
    Delete "$DESKTOP\DonutRadio.lnk"

    ; Remove registry keys
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\DonutRadio"
    DeleteRegKey HKLM "Software\DonutRadio"
SectionEnd

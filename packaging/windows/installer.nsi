; Free Radio NSIS Installer Script
; Requires: NSIS 3.x

!include "MUI2.nsh"

; General
Name "Free Radio"
OutFile "FreeRadio-2.0.0-Setup.exe"
InstallDir "$PROGRAMFILES64\Free Radio"
InstallDirRegKey HKLM "Software\Free Radio" "Install_Dir"
RequestExecutionLevel admin

; Interface Settings
!define MUI_ABORTWARNING
!define MUI_ICON "..\..\freeradio\icons\freeradio.ico"
!define MUI_UNICON "..\..\freeradio\icons\freeradio.ico"

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
Section "Free Radio" SecMain
    SetOutPath $INSTDIR

    ; Copy application files
    File /r "..\..\build-windows\release\*.*"

    ; Copy Qt plugins and QML modules
    SetOutPath $INSTDIR\platforms
    File /r "..\..\build-windows\release\platforms\*.*"

    SetOutPath $INSTDIR\styles
    File /r "..\..\build-windows\release\styles\*.*"

    ; Create shortcuts
    CreateDirectory "$SMPROGRAMS\Free Radio"
    CreateShortcut "$SMPROGRAMS\Free Radio\Free Radio.lnk" "$INSTDIR\freeradio.exe"
    CreateShortcut "$SMPROGRAMS\Free Radio\Uninstall.lnk" "$INSTDIR\uninstall.exe"
    CreateShortcut "$DESKTOP\Free Radio.lnk" "$INSTDIR\freeradio.exe"

    ; Write registry keys
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FreeRadio" "DisplayName" "Free Radio"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FreeRadio" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FreeRadio" "DisplayIcon" "$INSTDIR\freeradio.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FreeRadio" "Publisher" "Free Radio Project"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FreeRadio" "DisplayVersion" "2.0.0"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FreeRadio" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FreeRadio" "NoRepair" 1

    ; Create uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

; Uninstaller Section
Section "Uninstall"
    ; Remove files
    RMDir /r "$INSTDIR"

    ; Remove shortcuts
    Delete "$SMPROGRAMS\Free Radio\*.*"
    RMDir "$SMPROGRAMS\Free Radio"
    Delete "$DESKTOP\Free Radio.lnk"

    ; Remove registry keys
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FreeRadio"
    DeleteRegKey HKLM "Software\Free Radio"
SectionEnd

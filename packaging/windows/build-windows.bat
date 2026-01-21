@echo off
REM Build Windows installer for Free Radio
REM Requirements: Qt6, CMake, NSIS, Visual Studio

setlocal

set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..\..
set BUILD_DIR=%PROJECT_DIR%\build-windows

echo Building Free Radio for Windows...
echo Project directory: %PROJECT_DIR%

REM Clean and create build directory
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"
cd "%BUILD_DIR%"

REM Configure and build
cmake "%PROJECT_DIR%\freeradio" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -G "Visual Studio 17 2022" ^
    -A x64

cmake --build . --config Release --parallel

REM Create release directory
mkdir release
copy Release\freeradio.exe release\

REM Deploy Qt libraries
windeployqt --qmldir "%PROJECT_DIR%\freeradio\contents\ui" release\freeradio.exe

REM Build installer
cd "%SCRIPT_DIR%"
makensis installer.nsi

echo Windows build complete!
dir *.exe

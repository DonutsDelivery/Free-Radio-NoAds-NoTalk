cmake_minimum_required(VERSION 3.16)
project(FreeRadioWidget)

# Set up for KDE Plasma widget development
find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

# Find required Qt and KDE components
find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick)
find_package(KF6 REQUIRED COMPONENTS Plasma I18n)

# Add the freeradio plasmoid
add_subdirectory(freeradio)
add_subdirectory(freeradio-panel)
add_subdirectory(freeradio-remote)
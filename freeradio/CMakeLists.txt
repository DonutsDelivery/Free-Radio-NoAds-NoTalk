cmake_minimum_required(VERSION 3.16)

project(FreeRadioApp VERSION 2.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable Qt's MOC and automatic handling
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find required Qt components
find_package(Qt6 REQUIRED COMPONENTS Core Widgets Qml Quick QuickControls2 Multimedia)

# Find KDE Frameworks 6 Kirigami
find_package(KF6Kirigami REQUIRED)

# Find PulseAudio (Linux only - optional for cross-platform)
find_package(PkgConfig)
if(PkgConfig_FOUND)
    pkg_check_modules(PULSEAUDIO libpulse libpulse-simple)
endif()

# Add executables
set(FREERADIO_SOURCES
    main.cpp
    AudioCapture.cpp
    AudioCapture.h
    resources.qrc
)

# Add Windows icon resource
if(WIN32)
    list(APPEND FREERADIO_SOURCES freeradio.rc)
endif()

add_executable(freeradio ${FREERADIO_SOURCES})

# Optional test executable
if(PULSEAUDIO_FOUND)
    add_executable(test-audio
        test_audio.cpp
        AudioCapture.cpp
        AudioCapture.h
    )
endif()

# Link Qt and Kirigami libraries
target_link_libraries(freeradio PRIVATE
    Qt6::Core
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    KF6::Kirigami
)

# Optional PulseAudio support
if(PULSEAUDIO_FOUND)
    target_link_libraries(freeradio PRIVATE ${PULSEAUDIO_LIBRARIES})
    target_include_directories(freeradio PRIVATE ${PULSEAUDIO_INCLUDE_DIRS})
    target_compile_definitions(freeradio PRIVATE ${PULSEAUDIO_CFLAGS_OTHER} HAVE_PULSEAUDIO)

    target_link_libraries(test-audio PRIVATE
        Qt6::Core
        Qt6::Multimedia
        ${PULSEAUDIO_LIBRARIES}
    )
    target_include_directories(test-audio PRIVATE ${PULSEAUDIO_INCLUDE_DIRS})
    target_compile_definitions(test-audio PRIVATE ${PULSEAUDIO_CFLAGS_OTHER})
endif()

# Set output directory for QML modules
set_target_properties(freeradio PROPERTIES
    QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

# Installation rules
include(GNUInstallDirs)

install(TARGETS freeradio
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES freeradio.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)

install(FILES icons/freeradio.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
)
